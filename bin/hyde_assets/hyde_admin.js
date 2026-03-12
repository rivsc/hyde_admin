$(function(){
    $(document).on('click','#btn-deploy,#btn-rebuild',function(e){
        e.preventDefault();
        var id = $(this).attr('id');
        var path = '';

        if(id === 'btn-deploy'){
            path = '/deploy';
        }else if(id === 'btn-rebuild'){
            path = '/rebuild';
        }

        $('#waiting').show();
        $.post(path)
            .always(function() {
                $('#waiting').hide();
            });
    });
    $(document).on('click','.form-confirm',function(){
        return window.confirm($(this).attr('data-confirm'));
    });
});
