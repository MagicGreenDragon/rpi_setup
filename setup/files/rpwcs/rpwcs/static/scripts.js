function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function raspi_exec_service_op(service_name, op_name, elem_id, reload) {
    // compose url
    var url = './' + service_name + '/' + op_name;
    // get elem
    if (!!elem_id){
        var elem_obj = document.getElementById(elem_id);
        // status -> wait
        elem_obj.className = 'op_res_wait';
        elem_obj.innerText = 'Waiting...';
    }
    // init request obj
    var delay_seconds = 3;
    var xmlHttp = new XMLHttpRequest();
    // set callback actions
    xmlHttp.onreadystatechange = async function() {
        console.log('[exec_service_op] URL = ' + url + ' ; readyState = ' + xmlHttp.readyState + ' ; status = ' + xmlHttp.status);
        if (xmlHttp.readyState == 4) {
            if (!!elem_obj){
                if (xmlHttp.status == 200){
                    var res = parseInt(xmlHttp.responseText);
                    if (res < 0){
                        // status -> System Exception
                        elem_obj.className = 'op_res_ex';
                        elem_obj.innerText = 'System Exception';
                    }
                    else if (res == 0){
                        elem_obj.className = 'op_res_ok';
                        // status -> OK
                        if (!!reload){
                            elem_obj.innerText = 'OK - Reloading...';
                            await sleep(delay_seconds * 1000);
                            location.reload();
                        }
                        else{
                            elem_obj.innerText = 'OK';
                        }
                    }
                    else{
                        // status -> KO
                        elem_obj.className = 'op_res_ko';
                        elem_obj.innerText = 'KO';
                    }
                }
                else{
                    // status -> Request Exception
                    elem_obj.className = 'op_res_ex';
                    elem_obj.innerText = 'Request Exception';
                }
            }
        }
    }
    // exec request
    xmlHttp.open("GET", url, true); // true for asynchronous 
    xmlHttp.send(null);
}
