$(function(){
    $(document).on('click','#btn-deploy,#btn-rebuild',function(elt){
        let path = '';

        if(elt.id === 'btn-deploy'){
            path = '/deploy';
        }else if(elt.id === 'btn-rebuild'){
            path = '/rebuild';
        }

        $.post( path, {
            beforeSend: function( xhr ) {
                $('#waiting').show();
            }
        })
            .done(function( data ) {
                $('#waiting').hide();
                return false;
            });
    });
    $(document).on('click','.form-confirm',function(){
        return window.confirm($(this).attr('data-confirm'));
    });
});