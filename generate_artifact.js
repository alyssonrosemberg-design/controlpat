const fs = require('fs');
const path = require('path');

const b64Brasao = fs.readFileSync('d:/Projeto APK Patrimonio/brasao_base64.txt', 'utf8').trim();
const qrcodeScript = fs.readFileSync('d:/Projeto APK Patrimonio/vendor/qrcode.min.js', 'utf8');

const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Modelo de Etiqueta Patrimonial com QR Code</title>
  <script src="https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js"></script>
  <style>
    .plaqueta-etiqueta {
      width: 100%;
      max-width: 540px;
      aspect-ratio: 3.4 / 1;
      background: #ffffff;
      color: #000000;
      border: 1.5px solid #c8cbcf;
      border-radius: 6px;
      box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08);
      display: flex;
      align-items: center;
      padding: 10px 14px;
      gap: 12px;
      font-family: Arial, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      box-sizing: border-box;
      user-select: none;
    }

    .plaqueta-brasao {
      flex: 0 0 20%;
      height: 90%;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .plaqueta-brasao img {
      max-height: 100%;
      max-width: 100%;
      object-fit: contain;
    }

    .plaqueta-corpo {
      flex: 1 1 auto;
      display: flex;
      flex-direction: column;
      justify-content: center;
      min-width: 0;
      padding: 0 2px;
    }

    .plaqueta-tombo {
      font-size: clamp(15px, 2.9vw, 21px);
      font-weight: 800;
      letter-spacing: 0.5px;
      color: #000;
      line-height: 1.1;
      margin-bottom: 5px;
      text-align: center;
    }

    .plaqueta-desc {
      font-size: clamp(11px, 2.1vw, 13.5px);
      font-weight: 700;
      text-transform: uppercase;
      color: #000;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      line-height: 1.2;
      margin-bottom: 3px;
    }

    .plaqueta-local {
      font-size: clamp(10px, 1.8vw, 12px);
      font-weight: 500;
      text-transform: uppercase;
      color: #111;
      line-height: 1.25;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }

    .plaqueta-qr {
      flex: 0 0 24%;
      aspect-ratio: 1 / 1;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .plaqueta-qr svg {
      width: 100%;
      height: 100%;
      display: block;
    }

    @media print {
      body * { visibility: hidden; }
      #printable-area, #printable-area * { visibility: visible; }
      #printable-area { position: absolute; left: 0; top: 0; }
    }
  </style>
</head>
<body class="bg-transparent text-[var(--foreground)] antialiased p-4 sm:p-6">
  <div class="bg-[var(--card)] text-[var(--foreground)] border border-[var(--border)] rounded-2xl p-6 shadow-md max-w-4xl mx-auto">
    
    <!-- Cabeçalho -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-5 border-b border-[var(--border)]">
      <div>
        <div class="inline-flex items-center gap-2 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-500 border border-emerald-500/20 mb-2">
          <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
          Layout Aprovado e Aplicado no Sistema
        </div>
        <h1 class="text-xl sm:text-2xl font-bold tracking-tight">Etiquetas com Padrão PAT-0000000000</h1>
        <p class="text-sm text-[var(--muted-foreground)] mt-1">
          Brasão de Anchieta, numeração de patrimônio formatada no padrão oficial e QR Code atualizado.
        </p>
      </div>
      <div class="flex items-center gap-2 shrink-0">
        <button onclick="window.print()" class="px-3.5 py-2 rounded-xl text-xs font-medium border border-[var(--border)] bg-[var(--background)] hover:bg-[var(--border)] transition">
          🖨️ Testar Impressão
        </button>
      </div>
    </div>

    <!-- Comparativo Visual -->
    <div class="my-6 grid grid-cols-1 md:grid-cols-2 gap-5">
      
      <!-- Lado 1: Original -->
      <div class="p-4 rounded-xl border border-[var(--border)] bg-[var(--background)] flex flex-col justify-between">
        <div>
          <span class="text-xs font-semibold tracking-wider uppercase text-amber-500 block mb-1">1. Foto Original Anexada</span>
          <p class="text-xs text-[var(--muted-foreground)] mb-3">Plaqueta física antiga colada no computador.</p>
        </div>
        <div class="rounded-lg overflow-hidden border border-[var(--border)] bg-black/5 flex items-center justify-center p-2">
          <img src="file:///C:/Users/alysson.schayder/.gemini/antigravity/brain/6abb4603-c4ee-418e-909f-a3d43d8b8836/etiqueta_original_crop.png" 
               alt="Etiqueta Original" 
               class="w-full object-contain rounded">
        </div>
      </div>

      <!-- Lado 2: Novo Modelo -->
      <div class="p-4 rounded-xl border-2 border-emerald-500/50 bg-emerald-500/[0.03] flex flex-col justify-between">
        <div>
          <span class="text-xs font-semibold tracking-wider uppercase text-emerald-500 block mb-1">2. Modelo Implementado (PAT-0000000000)</span>
          <p class="text-xs text-[var(--muted-foreground)] mb-3">Brasão de Anchieta oficial + Numeração PAT padronizada.</p>
        </div>
        <div id="printable-area" class="flex items-center justify-center p-1">
          <div class="plaqueta-etiqueta">
            <div class="plaqueta-brasao">
              <img src="${b64Brasao}" alt="Brasão" />
            </div>
            <div class="plaqueta-corpo">
              <div id="view-tombo" class="plaqueta-tombo">PAT-0000029794</div>
              <div id="view-desc" class="plaqueta-desc">COMPUTADOR DESKTOP</div>
              <div id="view-local" class="plaqueta-local">SECRETARIA DE ASSISTENCIA SOCIAL</div>
            </div>
            <div id="view-qr" class="plaqueta-qr"></div>
          </div>
        </div>
      </div>

    </div>

    <!-- Simulador Interativo -->
    <div class="p-5 rounded-xl border border-[var(--border)] bg-[var(--background)]">
      <h3 class="text-sm font-semibold text-[var(--foreground)] mb-3 flex items-center gap-2">
        <span>⚙️</span> Teste Interativo:
      </h3>
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <div>
          <label class="block text-xs font-medium text-[var(--muted-foreground)] mb-1">Nº do Patrimônio (Tombo)</label>
          <input type="text" id="input-tombo" value="PAT-0000029794" 
                 class="w-full px-3 py-1.5 text-sm rounded-lg border border-[var(--border)] bg-[var(--card)] text-[var(--foreground)] focus:outline-none focus:ring-1 focus:ring-emerald-500">
        </div>
        <div>
          <label class="block text-xs font-medium text-[var(--muted-foreground)] mb-1">Descrição do Bem</label>
          <input type="text" id="input-desc" value="COMPUTADOR DESKTOP" 
                 class="w-full px-3 py-1.5 text-sm rounded-lg border border-[var(--border)] bg-[var(--card)] text-[var(--foreground)] focus:outline-none focus:ring-1 focus:ring-emerald-500">
        </div>
        <div>
          <label class="block text-xs font-medium text-[var(--muted-foreground)] mb-1">Secretaria / Setor</label>
          <input type="text" id="input-local" value="SECRETARIA DE ASSISTENCIA SOCIAL" 
                 class="w-full px-3 py-1.5 text-sm rounded-lg border border-[var(--border)] bg-[var(--card)] text-[var(--foreground)] focus:outline-none focus:ring-1 focus:ring-emerald-500">
        </div>
      </div>
      <div class="flex flex-wrap gap-2 mt-3">
        <span class="text-xs text-[var(--muted-foreground)] self-center">Simulações:</span>
        <button onclick="carregarExemplo('PAT-0000029794', 'COMPUTADOR DESKTOP', 'SECRETARIA DE ASSISTENCIA SOCIAL')" class="text-xs px-2.5 py-1 rounded-md bg-[var(--card)] border border-[var(--border)] hover:border-emerald-500 transition">Exemplo Foto (29794)</button>
        <button onclick="carregarExemplo('PAT-0000000001', 'AR CONDICIONADO SPLIT 12000 BTUS', 'SECRETARIA DE EDUCACAO')" class="text-xs px-2.5 py-1 rounded-md bg-[var(--card)] border border-[var(--border)] hover:border-emerald-500 transition">PAT-0000000001 (Educação)</button>
        <button onclick="carregarExemplo('PAT-0000000142', 'VEICULO AMBULANCIA RENAULT', 'SECRETARIA DE SAUDE')" class="text-xs px-2.5 py-1 rounded-md bg-[var(--card)] border border-[var(--border)] hover:border-emerald-500 transition">PAT-0000000142 (Saúde)</button>
      </div>
    </div>

  </div>

  <script>
    ${qrcodeScript}

    function formatTombo(t) {
      if (!t) return 'PAT-0000000000';
      const raw = String(t).trim();
      const digits = raw.replace(/\\D/g, '');
      if (!digits) return raw.toUpperCase();
      return 'PAT-' + digits.padStart(10, '0');
    }

    function renderQR(texto) {
      try {
        const q = qrcode(0, 'M');
        q.addData(texto || 'PAT-0000000000');
        q.make();
        document.getElementById('view-qr').innerHTML = q.createSvgTag(4, 0);
      } catch (e) {
        console.error('Erro ao gerar QR:', e);
      }
    }

    const inTombo = document.getElementById('input-tombo');
    const inDesc = document.getElementById('input-desc');
    const inLocal = document.getElementById('input-local');

    function updatePreview() {
      const formattedTombo = formatTombo(inTombo.value);
      const desc = inDesc.value.trim() || 'DESCRICAO DO BEM';
      const local = inLocal.value.trim() || 'SECRETARIA / SETOR';

      document.getElementById('view-tombo').textContent = formattedTombo;
      document.getElementById('view-desc').textContent = desc;
      document.getElementById('view-local').textContent = local;
      renderQR(formattedTombo);
    }

    inTombo.addEventListener('input', updatePreview);
    inDesc.addEventListener('input', updatePreview);
    inLocal.addEventListener('input', updatePreview);

    function carregarExemplo(t, d, l) {
      inTombo.value = t;
      inDesc.value = d;
      inLocal.value = l;
      updatePreview();
    }

    updatePreview();
  </script>
</body>
</html>`;

const outPath = 'C:/Users/alysson.schayder/.gemini/antigravity/brain/6abb4603-c4ee-418e-909f-a3d43d8b8836/etiqueta_preview.html';
fs.writeFileSync(outPath, html, 'utf8');
console.log('HTML artifact updated successfully at:', outPath);
