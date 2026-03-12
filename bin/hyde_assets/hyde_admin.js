document.addEventListener('DOMContentLoaded', function(){
    document.addEventListener('click', function(e){
        var btn = e.target.closest('#btn-deploy, #btn-rebuild');
        if(!btn) return;
        e.preventDefault();
        var path = '';
        if(btn.id === 'btn-deploy'){
            path = '/deploy';
        }else if(btn.id === 'btn-rebuild'){
            path = '/rebuild';
        }
        document.getElementById('waiting').style.display = 'block';
        fetch(path, { method: 'POST' })
            .finally(function() {
                document.getElementById('waiting').style.display = 'none';
            });
    });
    document.addEventListener('submit', function(e){
        var form = e.target.closest('.form-confirm');
        if(!form) return;
        if(!window.confirm(form.getAttribute('data-confirm'))){
            e.preventDefault();
        }
    });
});
