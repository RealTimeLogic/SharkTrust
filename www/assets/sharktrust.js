

/* formatString('You have {0} cars and {1} bikes', 'two', 'three')
 * returns 'You have two cars and three bikes'
*/
const formatString = (str, ...params) => {
    for (let i = 0; i < params.length; i++) {
        var reg = new RegExp("\\{" + i + "\\}", "gm");
        str = str.replace(reg, params[i]);
    }
    return str;
};

const details=`
<tr id="details"><td colspan=3>
<table class="table table-dark"><tbody>
  <tr><td>Access:</td><td>{0}</td></tr>
  <tr><td>Cert. Exp:</td><td>{1}</td></tr>
  <tr><td>Details:</td><td>{2}</td></tr>
  <tr><td>Key:</td><td>{3}</td></tr>
</tbody></table>
<div class="mx-auto" style="width: 200px;">{4}</div>
</td></tr>
`;

const rembut=
    '<button type="button" class="btn btn-danger">Remove Device</button>';


$(function() {
    let lastErrowE=null;
    let lastIndex=-1;
    $(".devtab > tr").each(function(index) {
        const trE=$(this);
        let name=$(".name", this).html()
        let up=false;
        $(".info", this).click(function() {
            const arrowE=$("div",this);
            if(lastErrowE) {
                lastErrowE.removeClass("uarrow").addClass("darrow");
                $("#details").remove();
                lastErrowE=null;
                if(lastIndex == index) {
                    lastIndex=-1;
                    return
                }
            }
            $.getJSON("rpc/details.lsp", {name:name}, function(rsp) {
                arrowE.removeClass("darrow").addClass("uarrow");
                lastErrowE=arrowE;
                trE.after(formatString(
                    details,
                    (new Date(rsp.atime*1000)).toLocaleString(),
                    rsp.exptime?  (new Date(rsp.exptime*1000)).toLocaleString() : "Not issued",
                    rsp.info ? rsp.info : "Not provided",
                    rsp.dkey ? rsp.dkey : "Hidden",
                    rsp.canrem ? rembut : ""));
                if(rsp.canrem) {
                    trE.next().find("button").click(function() {
                        $.getJSON("rpc/deletedevice.lsp", {name:name},
                          function(rsp) {
                            if(rsp.ok) {
                                $("#details").remove();
                                lastErrowE=null;
                                trE.remove();
                            }
                            else
                                location.reload();
                        });
                    });
                }
                up=true;
                lastIndex = index;
            });
        })
    });
});

