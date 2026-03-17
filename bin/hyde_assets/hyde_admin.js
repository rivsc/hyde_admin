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

    // Autosave
    var autosaveForm = document.querySelector('form[data-autosave-key]');
    if (autosaveForm) {
        var autosaveKey = autosaveForm.getAttribute('data-autosave-key');
        var autosaveInterval = 15000;
        var autosaveTimer = null;
        var autosaveFields = ['i-title', 'i-date', 'i-tags'];

        function autosaveGetContent() {
            if (window.myCodeMirror) return window.myCodeMirror.getValue();
            var ta = document.getElementById('i-content');
            return ta ? ta.value : '';
        }

        function autosaveSetContent(val) {
            if (window.myCodeMirror) { window.myCodeMirror.setValue(val); return; }
            var ta = document.getElementById('i-content');
            if (ta) ta.value = val;
        }

        function autosaveCollect() {
            var data = { _ts: Date.now() };
            autosaveFields.forEach(function(id) {
                var el = document.getElementById(id);
                if (el) data[id] = el.value;
            });
            var layoutEl = autosaveForm.querySelector('select[name="layout"]');
            if (layoutEl) data['layout'] = layoutEl.value;
            data['content'] = autosaveGetContent();
            return data;
        }

        function autosaveSave() {
            try {
                localStorage.setItem(autosaveKey, JSON.stringify(autosaveCollect()));
                var ind = document.getElementById('autosave-indicator');
                if (ind) {
                    ind.classList.add('visible');
                    setTimeout(function() { ind.classList.remove('visible'); }, 2000);
                }
            } catch(e) {}
        }

        function autosaveRestore(data) {
            autosaveFields.forEach(function(id) {
                var el = document.getElementById(id);
                if (el && data[id] !== undefined) el.value = data[id];
            });
            var layoutEl = autosaveForm.querySelector('select[name="layout"]');
            if (layoutEl && data['layout']) layoutEl.value = data['layout'];
            if (data['content'] !== undefined) autosaveSetContent(data['content']);
        }

        function autosaveShowBanner(data) {
            var banner = document.getElementById('autosave-banner');
            if (!banner) return;
            var dateStr = new Date(data._ts).toLocaleString();
            document.getElementById('autosave-banner-text').textContent =
                'Autosaved draft from ' + dateStr;
            banner.classList.remove('d-none');

            document.getElementById('autosave-restore').addEventListener('click', function() {
                autosaveRestore(data);
                banner.classList.add('d-none');
            });
            document.getElementById('autosave-discard').addEventListener('click', function() {
                localStorage.removeItem(autosaveKey);
                banner.classList.add('d-none');
            });
        }

        function autosaveInit() {
            try {
                var raw = localStorage.getItem(autosaveKey);
                if (raw) {
                    var data = JSON.parse(raw);
                    if (Date.now() - data._ts < 7 * 24 * 3600 * 1000) {
                        autosaveShowBanner(data);
                    } else {
                        localStorage.removeItem(autosaveKey);
                    }
                }
            } catch(e) { localStorage.removeItem(autosaveKey); }

            autosaveTimer = setInterval(autosaveSave, autosaveInterval);

            autosaveForm.addEventListener('submit', function() {
                localStorage.removeItem(autosaveKey);
                if (autosaveTimer) clearInterval(autosaveTimer);
            });
        }

        // Wait for CodeMirror to be ready
        (function waitCM(attempts) {
            if (window.myCodeMirror || attempts <= 0) {
                autosaveInit();
            } else {
                setTimeout(function() { waitCM(attempts - 1); }, 100);
            }
        })(20);
    }
});
