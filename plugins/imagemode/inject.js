// SimplePOSPrint inject.js (text mode + logo marker, print dialog suppressed)

(function () {
    // === CONFIG ===
    const PRINT_RECEIPT_SELECTOR = 'button[data-track="print-receipt…"]';
    const GIFT_RECEIPT_SELECTOR = 'button[data-track="gift-receipt"]';
    const TEMPLATE_LIST_SELECTOR = '.vd-popover-list-item';

    // === UTILS ===
    function toast(msg, ok = true) {
        let el = document.getElementById('simpleposprint-toast');
        if (!el) {
            el = document.createElement('div');
            el.id = 'simpleposprint-toast';
            Object.assign(el.style, {
                position: 'fixed', top: '30px', right: '30px',
                padding: '1em 1.4em', borderRadius: '0.5em',
                background: ok ? '#3bb54a' : '#d8342c', color: '#fff',
                fontWeight: 'bold', fontSize: '1.1em', zIndex: 99999,
                boxShadow: '0 3px 16px #0004', opacity: 0.95,
            });
            document.body.appendChild(el);
        }
        el.textContent = msg;
        el.style.display = 'block';
        setTimeout(() => { el.style.display = 'none'; }, 3200);
    }

    function sendTextReceiptToPOSPrint(receiptText, type) {
        fetch("http://127.0.0.1:5000/print", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ type: "text", data: receiptText })
        })
        .then(r => {
            if (r.ok) toast(type + " sent to till printer!");
            else toast("Failed to print " + type, false);
        })
        .catch(err => {
            console.error("[SimplePOSPrint] Error sending text:", err);
            toast("Error sending to till printer.", false);
        });
    }

    // Helper: Extract receipt text from the correct iframe
    function extractReceiptTextFromIframe(expectGift) {
        const iframes = Array.from(document.querySelectorAll('iframe.sale-table-sale-receipt'));
        const visibleIframes = iframes.filter(iframe => {
            try {
                const style = getComputedStyle(iframe);
                return style.display !== 'none' && style.visibility !== 'hidden' && iframe.offsetWidth > 0 && iframe.offsetHeight > 0;
            } catch {
                return false;
            }
        });
        const candidates = visibleIframes.length ? visibleIframes : iframes;
        for (let i = candidates.length - 1; i >= 0; i--) {
            const iframe = candidates[i];
            try {
                const doc = iframe.contentDocument || iframe.contentWindow?.document;
                if (!doc) continue;
                const selectors = [
                    '[data-testid="receipt-preview-container"]',
                    '.print-preview-container',
                    '.receipt-preview',
                    '.vd-receipt-preview',
                    'body'
                ];
                for (const sel of selectors) {
                    let node = doc.querySelector(sel);
                    if (node) {
                        let text = node.innerText || node.textContent || "";
                        const isGift = /gift receipt/i.test(text) || /no prices|this receipt is for gifts/i.test(text);
                        if (expectGift && isGift) return text;
                        if (!expectGift && !isGift && /total|subtotal|payment|vat|card/i.test(text)) return text;
                    }
                }
            } catch (e) { /* cross-origin, ignore */ }
        }
        return null;
    }

    function interceptTemplateAfter(buttonType) {
        const handler = function (event) {
            event.preventDefault();
            event.stopImmediatePropagation();
            setTimeout(() => {
                let isGift = buttonType === 'gift';
                let text = extractReceiptTextFromIframe(isGift);
                if (text) {
                    // Add the logo marker to the top (your backend will handle the actual image)
                    const receiptWithLogo = '[[LOGO]]\n' + text;
                    sendTextReceiptToPOSPrint(receiptWithLogo, isGift ? "Gift receipt" : "Standard receipt");
                } else {
                    toast("Could not extract " + (isGift ? "gift" : "standard") + " receipt.", false);
                }
            }, 1000);
            return false;
        };
        document.querySelectorAll(TEMPLATE_LIST_SELECTOR).forEach(item => {
            item.addEventListener('click', handler, { once: true });
        });
    }

    function setupButtonHandler(selector, type) {
        const button = document.querySelector(selector);
        if (!button) return;
        button.addEventListener('click', () => {
            const mo = new MutationObserver(() => {
                if (document.querySelector(TEMPLATE_LIST_SELECTOR)) {
                    interceptTemplateAfter(type);
                    mo.disconnect();
                }
            });
            mo.observe(document.body, { childList: true, subtree: true });
        });
    }

    function setupAll() {
        setupButtonHandler(PRINT_RECEIPT_SELECTOR, 'standard');
        setupButtonHandler(GIFT_RECEIPT_SELECTOR, 'gift');
    }

    setupAll();
    const spaMo = new MutationObserver(setupAll);
    spaMo.observe(document.body, { childList: true, subtree: true });

    setTimeout(() => {
        toast("SimplePOSPrint loaded. Click Print or Gift receipt and choose a template.");
    }, 500);
})();