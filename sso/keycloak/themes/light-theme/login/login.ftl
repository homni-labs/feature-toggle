<#-- Togli — Light Theme (Comic Panel) -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Togli — Sign In</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Fredoka:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${url.resourcesPath}/css/styles.css">
</head>
<body>

<div class="page" id="page">

    <!-- ── Left Panel ────────────────────────────────────────── -->
    <div class="panel">
        <div class="panel-bg"><canvas id="c-left"></canvas></div>

        <div class="logo">
            <img src="${url.resourcesPath}/img/logo.jpeg" alt="Togli">
        </div>

        <div class="tagline">
            <div class="tl-row">
                <span class="w w-f">Feature</span>
                <span class="w w-p">+</span>
                <span class="w w-t">Toggle</span>
            </div>
            <div class="tl-row">
                <span class="w w-i">is</span>
                <span class="w w-g">Togli</span>
            </div>
        </div>

        <p class="origin-line" id="taglineQuote"></p>
    </div>

    <!-- ── Right Panel ───────────────────────────────────────── -->
    <div class="right">
        <div class="right-bg"><canvas id="c-right"></canvas></div>

        <div class="form-area">
            <div class="comic-card">
                <h2>Sign In!</h2>
                <p class="card-subtitle">Enter your credentials</p>

                <#if message?has_content && (message.type != 'warning' || !isAppInitiatedAction??)>
                    <div class="alert alert-${message.type}">
                        ${kcSanitize(message.summary)?no_esc}
                    </div>
                </#if>

                <form action="${url.loginAction}" method="post">
                    <input class="comic-fi"
                           type="text"
                           id="username"
                           name="username"
                           value="${(login.username!'')}"
                           placeholder="Email or username"
                           autocomplete="username"
                           autofocus>

                    <input class="comic-fi"
                           type="password"
                           id="password"
                           name="password"
                           placeholder="Password"
                           autocomplete="current-password">

                    <button type="submit" class="comic-btn">BAM! Let's Go</button>
                </form>

                <#if realm.password && social?? && social.providers?has_content>
                    <div style="display:flex;align-items:center;gap:14px;margin:18px 0 14px">
                        <span style="flex:1;height:2px;background:var(--cream-dark)"></span>
                        <span style="font-family:'Fredoka',sans-serif;font-size:12px;color:var(--navy-light);opacity:.4">or</span>
                        <span style="flex:1;height:2px;background:var(--cream-dark)"></span>
                    </div>
                    <div style="display:flex;gap:8px;flex-wrap:wrap">
                        <#list social.providers as p>
                            <a href="${p.loginUrl}"
                               style="flex:1;min-width:80px;height:44px;display:flex;align-items:center;justify-content:center;
                                      border:3px solid var(--navy);border-radius:6px;background:var(--cream-light);
                                      color:var(--navy);font-family:'Fredoka',sans-serif;font-size:13px;font-weight:600;
                                      text-decoration:none;box-shadow:3px 3px 0 var(--cream-dark);transition:all .1s"
                               onmouseover="this.style.boxShadow='3px 3px 0 var(--navy)'"
                               onmouseout="this.style.boxShadow='3px 3px 0 var(--cream-dark)'">
                                ${p.displayName}
                            </a>
                        </#list>
                    </div>
                </#if>
            </div>
        </div>
    </div>

</div>

<script src="${url.resourcesPath}/js/quotes.js"></script>
<script>
/* ── Trigger animations ────────────────────────────────────── */
requestAnimationFrame(function() { document.getElementById('page').classList.add('loaded'); });

/* ── Random tagline quote ──────────────────────────────────── */
(function() {
    var el = document.getElementById('taglineQuote');
    if (typeof QUOTES !== 'undefined' && QUOTES.length) {
        el.textContent = QUOTES[Math.floor(Math.random() * QUOTES.length)];
    }
})();

/* ── Canvas helpers ────────────────────────────────────────── */
var COLORS = ['#EF7B6C','#4ABFBF','#7BC67E','#BBA8D9','#F5C842'];

function drawToggle(ctx, x, y, w, h, color, on, alpha) {
    ctx.save();
    ctx.globalAlpha = alpha;
    var r = h / 2;
    ctx.beginPath();
    ctx.moveTo(x + r, y); ctx.lineTo(x + w - r, y);
    ctx.arc(x + w - r, y + r, r, -Math.PI / 2, Math.PI / 2);
    ctx.lineTo(x + r, y + h);
    ctx.arc(x + r, y + r, r, Math.PI / 2, -Math.PI / 2);
    ctx.closePath();
    ctx.fillStyle = on ? color : 'rgba(255,255,255,0.25)';
    ctx.fill();
    ctx.strokeStyle = 'rgba(255,255,255,0.3)';
    ctx.lineWidth = 2;
    ctx.stroke();
    var tr = r * 0.7;
    var tx = on ? x + w - r : x + r;
    ctx.beginPath();
    ctx.arc(tx, y + r, tr, 0, Math.PI * 2);
    ctx.fillStyle = '#fff';
    ctx.fill();
    ctx.stroke();
    ctx.restore();
}

/* ── LEFT — Floating toggles on coral ──────────────────────── */
(function() {
    var c = document.getElementById('c-left');
    if (!c) return;
    var ctx = c.getContext('2d');
    var items = [];
    var prevW = 0, prevH = 0;

    function initItems(w, h) {
        items = [];
        for (var i = 0; i < 16; i++) {
            var tw = Math.random() * 40 + 30;
            var th = tw * 0.48;
            items.push({
                x: Math.random() * w, y: Math.random() * h, w: tw, h: th,
                vx: (Math.random() - 0.5) * 0.5, vy: (Math.random() - 0.5) * 0.5,
                rot: Math.random() * 0.5 - 0.25, rotSpeed: (Math.random() - 0.5) * 0.003,
                on: Math.random() > 0.5, color: COLORS[Math.floor(Math.random() * 5)],
                toggleTimer: Math.random() * 3000 + 2000, alpha: Math.random() * 0.1 + 0.06
            });
        }
    }

    var last = 0;
    function draw(t) {
        var dt = t - last; last = t;
        var el = c.parentElement.parentElement;
        var w = el.offsetWidth, h = el.offsetHeight;
        if (w !== prevW || h !== prevH) {
            if (prevW > 0 && items.length) {
                var sx = w / prevW, sy = h / prevH;
                for (var j = 0; j < items.length; j++) { items[j].x *= sx; items[j].y *= sy; }
            }
            c.width = w; c.height = h;
            prevW = w; prevH = h;
            if (!items.length) initItems(w, h);
        }
        ctx.clearRect(0, 0, c.width, c.height);
        for (var k = 0; k < items.length; k++) {
            var it = items[k];
            it.x += it.vx; it.y += it.vy; it.rot += it.rotSpeed;
            if (it.x < -it.w) it.x = c.width + it.w;
            if (it.x > c.width + it.w) it.x = -it.w;
            if (it.y < -it.h) it.y = c.height + it.h;
            if (it.y > c.height + it.h) it.y = -it.h;
            it.toggleTimer -= dt;
            if (it.toggleTimer <= 0) { it.on = !it.on; it.toggleTimer = Math.random() * 4000 + 2000; }
            ctx.save();
            ctx.translate(it.x, it.y); ctx.rotate(it.rot);
            drawToggle(ctx, -it.w / 2, -it.h / 2, it.w, it.h, it.color, it.on, it.alpha);
            ctx.restore();
        }
        requestAnimationFrame(draw);
    }
    requestAnimationFrame(draw);
})();

/* ── RIGHT — Soft bouncing colored dots ────────────────────── */
(function() {
    var c = document.getElementById('c-right');
    if (!c) return;
    var ctx = c.getContext('2d');
    var dots = [];
    var prevW = 0, prevH = 0;

    function initDots(w, h) {
        dots = [];
        for (var i = 0; i < 20; i++) {
            dots.push({
                x: Math.random() * w, y: Math.random() * h,
                r: Math.random() * 30 + 12,
                vx: (Math.random() - 0.5) * 0.4, vy: (Math.random() - 0.5) * 0.4,
                color: COLORS[Math.floor(Math.random() * 5)],
                alpha: Math.random() * 0.06 + 0.03,
                pulse: Math.random() * Math.PI * 2, pulseSpeed: Math.random() * 0.01 + 0.005
            });
        }
    }

    function draw() {
        var el = c.parentElement.parentElement;
        var w = el.offsetWidth, h = el.offsetHeight;
        if (w < 2 || h < 2) { requestAnimationFrame(draw); return; }
        if (w !== prevW || h !== prevH) {
            c.width = w; c.height = h;
            prevW = w; prevH = h;
            if (!dots.length) initDots(w, h);
            for (var j = 0; j < dots.length; j++) {
                dots[j].x = Math.min(dots[j].x, w - dots[j].r);
                dots[j].y = Math.min(dots[j].y, h - dots[j].r);
            }
        }
        ctx.clearRect(0, 0, c.width, c.height);
        for (var k = 0; k < dots.length; k++) {
            var d = dots[k];
            d.x += d.vx; d.y += d.vy; d.pulse += d.pulseSpeed;
            if (d.x - d.r < 0 || d.x + d.r > c.width) d.vx *= -1;
            if (d.y - d.r < 0 || d.y + d.r > c.height) d.vy *= -1;
            var scale = 1 + Math.sin(d.pulse) * 0.15;
            ctx.beginPath();
            ctx.arc(d.x, d.y, d.r * scale, 0, Math.PI * 2);
            ctx.fillStyle = d.color;
            ctx.globalAlpha = d.alpha;
            ctx.fill();
            ctx.strokeStyle = d.color;
            ctx.lineWidth = 1.5;
            ctx.globalAlpha = d.alpha * 0.5;
            ctx.stroke();
        }
        ctx.globalAlpha = 1;
        requestAnimationFrame(draw);
    }
    requestAnimationFrame(draw);
})();
</script>
</body>
</html>
