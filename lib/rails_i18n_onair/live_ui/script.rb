module RailsI18nOnair
  module LiveUi
    # Generates the self-contained <script>+<style> block that the middleware
    # injects into every HTML page.  All styles use [data-i18n-onair-*]
    # attribute selectors + !important so they render identically regardless
    # of the host app's CSS.
    module Script
      module_function

      def render(mount_path)
        <<~HTML
          <!-- RailsI18nOnair Live UI -->
          <style>#{css}</style>
          <script>#{js(mount_path)}</script>
        HTML
      end

      # ── CSS ────────────────────────────────────────────────────────────
      def css
        <<~CSS
          /* ── OnAir Live UI — scoped via attribute selectors ── */

          [data-i18n-onair-toolbar]{
            position:fixed!important;bottom:24px!important;right:24px!important;
            z-index:2147483647!important;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif!important;
            font-size:14px!important;line-height:1.4!important;direction:ltr!important;
          }

          [data-i18n-onair-fab]{
            width:48px!important;height:48px!important;border-radius:50%!important;
            border:none!important;cursor:pointer!important;
            background:linear-gradient(135deg,#667eea 0%,#764ba2 100%)!important;
            color:#fff!important;font-size:20px!important;
            box-shadow:0 4px 14px rgba(102,126,234,.45)!important;
            display:flex!important;align-items:center!important;justify-content:center!important;
            transition:transform .2s,box-shadow .2s!important;
          }
          [data-i18n-onair-fab]:hover{
            transform:scale(1.1)!important;
            box-shadow:0 6px 20px rgba(102,126,234,.6)!important;
          }

          [data-i18n-onair-panel]{
            position:absolute!important;bottom:60px!important;right:0!important;
            width:260px!important;background:#fff!important;border-radius:12px!important;
            box-shadow:0 8px 30px rgba(0,0,0,.18)!important;padding:16px!important;
            display:none!important;
          }
          [data-i18n-onair-panel][data-visible="true"]{display:block!important;}

          [data-i18n-onair-panel] h4{
            margin:0 0 12px!important;font-size:14px!important;font-weight:700!important;
            color:#333!important;display:flex!important;align-items:center!important;gap:6px!important;
          }
          [data-i18n-onair-panel] h4 span{
            background:linear-gradient(135deg,#667eea,#764ba2)!important;
            -webkit-background-clip:text!important;-webkit-text-fill-color:transparent!important;
          }

          [data-i18n-onair-toggle]{
            display:flex!important;align-items:center!important;justify-content:space-between!important;
            padding:10px 0!important;border-top:1px solid #eee!important;
          }
          [data-i18n-onair-toggle] label{
            font-size:13px!important;color:#555!important;font-weight:500!important;cursor:pointer!important;
          }

          /* Switch */
          [data-i18n-onair-switch]{
            position:relative!important;width:40px!important;height:22px!important;
            background:#ccc!important;border-radius:11px!important;cursor:pointer!important;
            transition:background .2s!important;border:none!important;padding:0!important;
          }
          [data-i18n-onair-switch][data-on="true"]{background:#667eea!important;}
          [data-i18n-onair-switch]::after{
            content:""!important;position:absolute!important;top:2px!important;left:2px!important;
            width:18px!important;height:18px!important;background:#fff!important;
            border-radius:50%!important;transition:transform .2s!important;
          }
          [data-i18n-onair-switch][data-on="true"]::after{transform:translateX(18px)!important;}

          /* Editable highlights */
          [data-i18n-onair="true"][data-i18n-onair-editing="true"]{
            outline:2px dashed rgba(102,126,234,.5)!important;
            outline-offset:2px!important;border-radius:3px!important;
            cursor:pointer!important;transition:outline-color .15s!important;
          }
          [data-i18n-onair="true"][data-i18n-onair-editing="true"]:hover{
            outline-color:rgba(118,75,162,.9)!important;
            background:rgba(102,126,234,.08)!important;
          }

          /* ── Popover editor ── */
          [data-i18n-onair-editor]{
            position:fixed!important;z-index:2147483647!important;
            width:340px!important;background:#fff!important;border-radius:10px!important;
            box-shadow:0 8px 30px rgba(0,0,0,.22)!important;padding:0!important;
            font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif!important;
            font-size:13px!important;overflow:hidden!important;
          }
          [data-i18n-onair-editor-header]{
            background:linear-gradient(135deg,#667eea 0%,#764ba2 100%)!important;
            padding:10px 14px!important;color:#fff!important;font-size:12px!important;
            display:flex!important;justify-content:space-between!important;align-items:center!important;
          }
          [data-i18n-onair-editor-header] code{
            background:rgba(255,255,255,.2)!important;padding:2px 6px!important;
            border-radius:4px!important;font-size:11px!important;color:#fff!important;
            max-width:200px!important;overflow:hidden!important;text-overflow:ellipsis!important;
            white-space:nowrap!important;
          }
          [data-i18n-onair-editor-close]{
            background:none!important;border:none!important;color:#fff!important;
            font-size:18px!important;cursor:pointer!important;padding:0!important;
            line-height:1!important;opacity:.8!important;
          }
          [data-i18n-onair-editor-close]:hover{opacity:1!important;}

          [data-i18n-onair-editor-body]{padding:14px!important;}

          [data-i18n-onair-editor-body] label{
            display:block!important;font-size:11px!important;font-weight:600!important;
            color:#888!important;text-transform:uppercase!important;letter-spacing:.5px!important;
            margin-bottom:4px!important;
          }
          [data-i18n-onair-editor-body] textarea{
            width:100%!important;min-height:60px!important;border:1px solid #ddd!important;
            border-radius:6px!important;padding:8px 10px!important;font-size:13px!important;
            font-family:inherit!important;resize:vertical!important;outline:none!important;
            color:#333!important;background:#fafafa!important;box-sizing:border-box!important;
          }
          [data-i18n-onair-editor-body] textarea:focus{
            border-color:#667eea!important;box-shadow:0 0 0 3px rgba(102,126,234,.15)!important;
          }

          [data-i18n-onair-editor-footer]{
            display:flex!important;justify-content:flex-end!important;gap:8px!important;
            padding:0 14px 14px!important;
          }
          [data-i18n-onair-btn]{
            padding:6px 16px!important;border-radius:6px!important;font-size:12px!important;
            font-weight:600!important;cursor:pointer!important;border:none!important;
            transition:opacity .15s!important;
          }
          [data-i18n-onair-btn-cancel]{background:#f0f0f0!important;color:#555!important;}
          [data-i18n-onair-btn-cancel]:hover{background:#e4e4e4!important;}
          [data-i18n-onair-btn-save]{
            background:linear-gradient(135deg,#667eea,#764ba2)!important;color:#fff!important;
          }
          [data-i18n-onair-btn-save]:hover{opacity:.9!important;}
          [data-i18n-onair-btn-save][disabled]{opacity:.5!important;cursor:not-allowed!important;}

          [data-i18n-onair-toast]{
            position:fixed!important;bottom:80px!important;right:24px!important;
            z-index:2147483647!important;padding:10px 18px!important;border-radius:8px!important;
            font-size:13px!important;font-weight:500!important;color:#fff!important;
            box-shadow:0 4px 14px rgba(0,0,0,.15)!important;
            opacity:0!important;transform:translateY(10px)!important;
            transition:opacity .25s,transform .25s!important;pointer-events:none!important;
            font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif!important;
          }
          [data-i18n-onair-toast][data-visible="true"]{
            opacity:1!important;transform:translateY(0)!important;
          }
          [data-i18n-onair-toast-success]{background:#28a745!important;}
          [data-i18n-onair-toast-error]{background:#dc3545!important;}
        CSS
      end

      # ── JavaScript ─────────────────────────────────────────────────────
      def js(mount_path)
        <<~JS
          (function(){
            "use strict";

            /* ── Config ── */
            var API = "#{mount_path}/api/live_translations";
            var CSRF = (document.querySelector('meta[name="csrf-token"]') || {}).content || "";

            var editMode = false;
            var editorEl = null;   // current popover
            var activeSpan = null; // span being edited

            /* ── Toolbar ── */
            function buildToolbar(){
              var root = document.createElement("div");
              root.setAttribute("data-i18n-onair-toolbar","");

              // FAB
              var fab = document.createElement("button");
              fab.setAttribute("data-i18n-onair-fab","");
              fab.innerHTML = "&#9998;"; // pencil
              fab.title = "I18n OnAir";
              root.appendChild(fab);

              // Panel
              var panel = document.createElement("div");
              panel.setAttribute("data-i18n-onair-panel","");
              panel.setAttribute("data-visible","false");

              panel.innerHTML =
                '<h4>&#127908; <span>I18n OnAir</span></h4>' +
                '<div data-i18n-onair-toggle>' +
                  '<label for="i18n-onair-edit-switch">Edit mode</label>' +
                  '<button id="i18n-onair-edit-switch" data-i18n-onair-switch data-on="false" title="Toggle edit mode"></button>' +
                '</div>';

              root.appendChild(panel);

              // Toggle panel visibility
              fab.addEventListener("click", function(){
                var vis = panel.getAttribute("data-visible") === "true";
                panel.setAttribute("data-visible", vis ? "false" : "true");
              });

              // Toggle edit mode
              var sw = panel.querySelector("[data-i18n-onair-switch]");
              sw.addEventListener("click", function(){
                editMode = !editMode;
                sw.setAttribute("data-on", editMode ? "true" : "false");
                toggleEditableHighlights(editMode);
                if(!editMode) closeEditor();
              });

              document.body.appendChild(root);
            }

            /* ── Highlight all editable spans ── */
            function toggleEditableHighlights(on){
              var spans = document.querySelectorAll("[data-i18n-onair]");
              for(var i=0;i<spans.length;i++){
                if(on){
                  spans[i].setAttribute("data-i18n-onair-editing","true");
                } else {
                  spans[i].removeAttribute("data-i18n-onair-editing");
                }
              }
            }

            /* ── Click handler ── */
            document.addEventListener("click", function(e){
              if(!editMode) return;

              var span = e.target.closest("[data-i18n-onair]");
              if(!span) return;

              // Ignore clicks inside the toolbar / editor
              if(e.target.closest("[data-i18n-onair-toolbar]") || e.target.closest("[data-i18n-onair-editor]")) return;

              e.preventDefault();
              e.stopPropagation();
              openEditor(span);
            }, true); // capture phase to intercept before host handlers

            /* ── Editor popover ── */
            function openEditor(span){
              closeEditor();
              activeSpan = span;

              var key    = span.getAttribute("data-i18n-key");
              var locale = span.getAttribute("data-i18n-locale");
              var value  = span.textContent;

              var el = document.createElement("div");
              el.setAttribute("data-i18n-onair-editor","");

              el.innerHTML =
                '<div data-i18n-onair-editor-header>' +
                  '<code title="' + escHtml(key) + '">' + escHtml(key) + '</code>' +
                  '<button data-i18n-onair-editor-close title="Close">&times;</button>' +
                '</div>' +
                '<div data-i18n-onair-editor-body>' +
                  '<label>Translation (' + escHtml(locale) + ')</label>' +
                  '<textarea data-i18n-onair-input>' + escHtml(value) + '</textarea>' +
                '</div>' +
                '<div data-i18n-onair-editor-footer>' +
                  '<button data-i18n-onair-btn data-i18n-onair-btn-cancel>Cancel</button>' +
                  '<button data-i18n-onair-btn data-i18n-onair-btn-save>Save</button>' +
                '</div>';

              document.body.appendChild(el);
              editorEl = el;

              // Position near the span
              positionEditor(el, span);

              // Focus textarea
              var ta = el.querySelector("textarea");
              ta.focus();
              ta.select();

              // Buttons
              el.querySelector("[data-i18n-onair-editor-close]").addEventListener("click", closeEditor);
              el.querySelector("[data-i18n-onair-btn-cancel]").addEventListener("click", closeEditor);
              el.querySelector("[data-i18n-onair-btn-save]").addEventListener("click", function(){
                var newVal = ta.value;
                saveTranslation(locale, key, newVal, span, el);
              });

              // Save on Ctrl/Cmd+Enter
              ta.addEventListener("keydown", function(ev){
                if((ev.ctrlKey || ev.metaKey) && ev.key === "Enter"){
                  ev.preventDefault();
                  var newVal = ta.value;
                  saveTranslation(locale, key, newVal, span, el);
                }
                if(ev.key === "Escape"){
                  ev.preventDefault();
                  closeEditor();
                }
              });
            }

            function positionEditor(el, span){
              var rect = span.getBoundingClientRect();
              var top  = rect.bottom + window.scrollY + 8;
              var left = rect.left + window.scrollX;

              // Keep within viewport
              var edW = 340;
              if(left + edW > window.innerWidth - 16) left = window.innerWidth - edW - 16;
              if(left < 16) left = 16;

              el.style.cssText += "top:" + top + "px!important;left:" + left + "px!important;";

              // If popover would go below viewport, show above the span instead
              requestAnimationFrame(function(){
                var edRect = el.getBoundingClientRect();
                if(edRect.bottom > window.innerHeight - 16){
                  var newTop = rect.top + window.scrollY - edRect.height - 8;
                  if(newTop < 16) newTop = 16;
                  el.style.top = newTop + "px";
                }
              });
            }

            function closeEditor(){
              if(editorEl){
                editorEl.remove();
                editorEl = null;
              }
              activeSpan = null;
            }

            /* ── Save via API ── */
            function saveTranslation(locale, key, value, span, editor){
              var btn = editor.querySelector("[data-i18n-onair-btn-save]");
              btn.setAttribute("disabled","");
              btn.textContent = "Saving\u2026";

              fetch(API + "/" + encodeURIComponent(locale), {
                method: "PATCH",
                headers: {
                  "Content-Type": "application/json",
                  "X-CSRF-Token": CSRF
                },
                body: JSON.stringify({ key: key, value: value }),
                credentials: "same-origin"
              })
              .then(function(res){ return res.json().then(function(d){ return {ok:res.ok,data:d}; }); })
              .then(function(r){
                if(r.ok){
                  span.textContent = value;
                  closeEditor();
                  showToast("Translation saved!", "success");
                } else {
                  btn.removeAttribute("disabled");
                  btn.textContent = "Save";
                  showToast(r.data.error || "Save failed", "error");
                }
              })
              .catch(function(){
                btn.removeAttribute("disabled");
                btn.textContent = "Save";
                showToast("Network error — please try again", "error");
              });
            }

            /* ── Toast ── */
            var toastTimer;
            function showToast(msg, type){
              var existing = document.querySelector("[data-i18n-onair-toast]");
              if(existing) existing.remove();
              clearTimeout(toastTimer);

              var t = document.createElement("div");
              t.setAttribute("data-i18n-onair-toast","");
              t.setAttribute("data-i18n-onair-toast-" + type,"");
              t.textContent = msg;
              document.body.appendChild(t);

              requestAnimationFrame(function(){
                t.setAttribute("data-visible","true");
              });

              toastTimer = setTimeout(function(){
                t.setAttribute("data-visible","false");
                setTimeout(function(){ t.remove(); }, 300);
              }, 3000);
            }

            /* ── Helpers ── */
            function escHtml(s){
              var d = document.createElement("div");
              d.textContent = s;
              return d.innerHTML;
            }

            /* ── Init ── */
            if(document.readyState === "loading"){
              document.addEventListener("DOMContentLoaded", buildToolbar);
            } else {
              buildToolbar();
            }
          })();
        JS
      end
    end
  end
end
