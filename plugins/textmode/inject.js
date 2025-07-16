(function () {
    console.log("[SimplePOSPrint] Extension loaded");

    // Toast message for staff feedback
    function toast(msg, ok = true) {
        let el = document.getElementById('simpleposprint-toast');
        if (!el) {
            el = document.createElement('div');
            el.id = 'simpleposprint-toast';
            el.style.position = 'fixed';
            el.style.top = '30px';
            el.style.right = '30px';
            el.style.padding = '1em 1.4em';
            el.style.borderRadius = '0.5em';
            el.style.background = ok ? '#3bb54a' : '#d8342c';
            el.style.color = '#fff';
            el.style.fontWeight = 'bold';
            el.style.fontSize = '1.1em';
            el.style.zIndex = 99999;
            el.style.boxShadow = '0 3px 16px #0004';
            el.style.opacity = 0.95;
            document.body.appendChild(el);
        }
        el.textContent = msg;
        el.style.display = 'block';
        setTimeout(() => { el.style.display = 'none'; }, 3200);
    }

    // Send text receipt to Flask backend
function sendReceiptToPOSPrint(receiptText) {
    fetch("http://127.0.0.1:5000/print", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ type: "text", data: receiptText })
    })
    .then(r => {
        if (r.ok) {
            toast("Receipt sent to till printer!");
            console.log("[SimplePOSPrint] Backend response OK");
        }
        else {
            r.text().then(txt => {
                console.error("[SimplePOSPrint] Backend returned error:", txt);
                toast("Failed to print (backend error)", false);
            });
        }
    })
    .catch(err => {
        console.error("[SimplePOSPrint] Fetch error:", err);
        toast("Error sending to till printer: " + err, false);
    });
}

    // Block all print dialogs (after sending the receipt)
    function blockPrintDialogs() {
        window.print = () => {};
        window.addEventListener('beforeprint', function(e) {
            e.stopImmediatePropagation();
            e.preventDefault();
        }, true);
        // Block in iframes, too
        document.querySelectorAll('iframe').forEach(frame => {
            try {
                frame.contentWindow.print = () => {};
            } catch (e) {}
        });
    }

    // Grab the receipt content with retries
    function waitForReceiptAndPrint(maxTries = 12) {
        let tries = 0;
        function tryOnce() {
            let container = null;
            const selectors = [
                '[data-testid="receipt-preview-container"]',
                '.print-preview-container',
                '.receipt-preview',
                '.vd-receipt-preview',
                'iframe'
            ];
            for (const selector of selectors) {
                const el = document.querySelector(selector);
                if (el) {
                    container = el;
                    break;
                }
            }
            let receiptText = "";
            if (container?.tagName === 'IFRAME') {
                try {
                    const iframeDoc = container.contentDocument || container.contentWindow?.document;
                    if (iframeDoc && iframeDoc.body && iframeDoc.body.innerText.trim().length > 10) {
                        receiptText = iframeDoc.body.innerText;
                    }
                } catch (e) {}
            } else if (container && container.innerText && container.innerText.trim().length > 10) {
                receiptText = container.innerText;
            }

            if (receiptText.length > 10) {
                sendReceiptToPOSPrint(receiptText);
                blockPrintDialogs();
                toast("Receipt sent to till printer!");
            } else if (++tries < maxTries) {
                setTimeout(tryOnce, 180); // Try up to ~2s
            } else {
                toast("Could not find receipt in DOM.", false);
                blockPrintDialogs();
            }
        }
        tryOnce();
    }

    // Attach handler to all .vd-popover-list-item buttons
    function interceptPrintTemplateSelection() {
        document.querySelectorAll('.vd-popover-list-item').forEach(item => {
            item.addEventListener('click', function(event) {
                event.preventDefault();
                event.stopImmediatePropagation();
                waitForReceiptAndPrint();
                return false;
            }, { once: true });
        });
    }

    // Watch for receipt template selector appearing
    const observer = new MutationObserver(() => {
        const popover = document.querySelector('.vd-popover-list-item');
        if (popover) {
            interceptPrintTemplateSelection();
        }
    });
    observer.observe(document.body, { childList: true, subtree: true });

    // Do not block print dialogs on page load; only after sending the receipt!
})();