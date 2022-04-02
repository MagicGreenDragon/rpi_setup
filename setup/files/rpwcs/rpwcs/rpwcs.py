import os
import requests
import threading
import time

from flask import Flask, render_template, send_from_directory


#### Utils ####

def exec_cmd(cmd, sleep_before=0):
    try:
        if sleep_before:
           time.sleep(sleep_before) 
        return str(os.system(cmd))
    except:
        return '-1'

def exec_cmd_nowait(cmd, sleep_before=0):
    try:
        t = threading.Thread(target=exec_cmd, args=(cmd, sleep_before))
        t.start()
        return '0'
    except:
        return '-1'

def service_check_status(s, check_service_ok_func):
    # check present
    is_present = int(exec_cmd('systemctl cat {}'.format(s))) == 0
    # check starting
    try:
        is_started = is_present and int(exec_cmd('systemctl is-active --quiet {}'.format(s))) == 0
    except:
        is_started = False
    # check started
    try:
        is_ok = is_started and check_service_ok_func()
    except:
        is_ok = False
    # result
    if is_ok:
        return 'Started'
    if is_started:
        return 'Starting...'
    if is_present:
        return 'Stopped'
    return 'Absent'

def service_exec_start(s):
    return exec_cmd('systemctl start {}'.format(s))

def service_exec_stop(s):
    return exec_cmd('systemctl stop {}'.format(s))

def service_exec_restart(s):
    return exec_cmd('systemctl restart {}'.format(s))


#### Setup Flask ####

rpwcs_app = Flask(__name__)

rpwcs_services = [
    'amule',
    'jdownloader',
    'jellyfin',
    'transmission'
]


#### Home ####

@rpwcs_app.route('/')
def rpwcs_index():
    # gather raspi system info
    raspi_system_info = {
        'temperature': rpwcs_raspi_get_temperature(),
        'mounts': rpwcs_raspi_get_mounts(),
    }
    
    # gather raspi services info
    raspi_services_info = []
    for s in rpwcs_services:
        d = dict(name=s)
        for i in ('displayname', 'status'):
            f = 'rpwcs_{}_{}'.format(s, i)
            d[i] = globals()[f]()
        raspi_services_info.append(d)
    
    # render template
    return render_template('index.htm.j2',
        raspi_system=raspi_system_info,
        raspi_services=raspi_services_info
    )

@rpwcs_app.route('/favicon.ico')
def rpwcs_favicon():
    return send_from_directory(os.path.join(rpwcs_app.root_path, 'static'), 'favicon.ico', mimetype='image/vnd.microsoft.icon')


#### Jellyfin ####

def jellyfin_check_status():
    try:
        return requests.get('http://127.0.0.1:8096/health', timeout=2).text == 'Healthy'
    except:
        return False

@rpwcs_app.route('/jellyfin/displayname')
def rpwcs_jellyfin_displayname():
    return 'Jellyfin'

@rpwcs_app.route('/jellyfin/status')
def rpwcs_jellyfin_status():
    return service_check_status('jellyfin', jellyfin_check_status)

@rpwcs_app.route('/jellyfin/start')
def rpwcs_jellyfin_start():
    return service_exec_start('jellyfin')

@rpwcs_app.route('/jellyfin/stop')
def rpwcs_jellyfin_stop():
    return service_exec_stop('jellyfin')

@rpwcs_app.route('/jellyfin/restart')
def rpwcs_jellyfin_restart():
    return service_exec_restart('jellyfin')


#### aMule ####

def amule_check_status():
    try:
        return requests.get('http://127.0.0.1:4711/', timeout=2).status_code == 200
    except:
        return False

@rpwcs_app.route('/amule/displayname')
def rpwcs_amule_displayname():
    return 'aMule'

@rpwcs_app.route('/amule/status')
def rpwcs_amule_status():
    return service_check_status('amule-daemon', amule_check_status)

@rpwcs_app.route('/amule/start')
def rpwcs_amule_start():
    return service_exec_start('amule-daemon')

@rpwcs_app.route('/amule/stop')
def rpwcs_amule_stop():
    return service_exec_stop('amule-daemon')

@rpwcs_app.route('/amule/restart')
def rpwcs_amule_restart():
    return service_exec_restart('amule-daemon')


#### Transmission ####

def transmission_check_status():
    try:
        return requests.get('http://127.0.0.1:9091/', timeout=2).status_code == 200
    except:
        return False

@rpwcs_app.route('/transmission/displayname')
def rpwcs_transmission_displayname():
    return 'Transmission'

@rpwcs_app.route('/transmission/status')
def rpwcs_transmission_status():
    return service_check_status('transmission-daemon', transmission_check_status)

@rpwcs_app.route('/transmission/start')
def rpwcs_transmission_start():
    return service_exec_start('transmission-daemon')

@rpwcs_app.route('/transmission/stop')
def rpwcs_transmission_stop():
    return service_exec_stop('transmission-daemon')

@rpwcs_app.route('/transmission/restart')
def rpwcs_transmission_restart():
    return service_exec_restart('transmission-daemon')


#### JDownloader ####

def jdownloader_check_status():
    return True

@rpwcs_app.route('/jdownloader/displayname')
def rpwcs_jdownloader_displayname():
    return 'JDownloader'

@rpwcs_app.route('/jdownloader/status')
def rpwcs_jdownloader_status():
    return service_check_status('jdownloader', jdownloader_check_status)

@rpwcs_app.route('/jdownloader/start')
def rpwcs_jdownloader_start():
    return service_exec_start('jdownloader')

@rpwcs_app.route('/jdownloader/stop')
def rpwcs_jdownloader_stop():
    return service_exec_stop('jdownloader')

@rpwcs_app.route('/jdownloader/restart')
def rpwcs_jdownloader_restart():
    return service_exec_restart('jdownloader')


#### RPi ####

@rpwcs_app.route('/raspi/temperature')
def rpwcs_raspi_get_temperature():
    try:
        return os.popen('vcgencmd measure_temp').read().strip().split('=')[-1]
    except:
        return 'Unknown'

@rpwcs_app.route('/raspi/mounts')
def rpwcs_raspi_get_mounts():
    try:
        return os.popen('df -h --output=target | grep "^/mnt"').read().strip().replace('\n', '<br/>')
    except:
        return 'Unknown'

@rpwcs_app.route('/raspi/remount')
def rpwcs_raspi_remount():
    return exec_cmd('mount -a')

@rpwcs_app.route('/raspi/shutdown')
def rpwcs_raspi_shutdown():
    return exec_cmd_nowait('shutdown -h now', sleep_before=2)

@rpwcs_app.route('/raspi/reboot')
def rpwcs_raspi_reboot():
    return exec_cmd_nowait('shutdown -r now', sleep_before=2)


#### MAIN ####

if __name__ == '__main__':
    rpwcs_app.run(debug=True, host='0.0.0.0', port=5000)
