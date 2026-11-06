# 🚀 Astra Valkyries: Void Protocol
## Agile Roadmap & Sprint Execution Plan

**Projeto:** *Astra Valkyries: Void Protocol*  
**Versão Atual:** Alpha 0.4.0  
**Stack:** Flutter + Flame (Engine 2D Vetorial) & Go Backend (Central Cloud API)  
**Data:** 06/11/2026  

---

### Visão Geral do Ciclo de Produção

```mermaid
flowchart TD
    S1["Sprint 1: Fundação Mobile & Radar"] --> S2["Sprint 2: Fórmula Vampire Survivors"]
    S2 --> S3["Sprint 3: Super-Evoluções & Chefe Leviathan"]
    S3 --> S4["Sprint 4: Meta-Progressão & Oficina do Hangar"]
    S4 --> S5["Sprint 5: Galeria de Waifus & Balanceamento Beta"]
```

---

## 🏁 SPRINT 1: Fundação Mobile-First, Setor 4.8k & Pilotos
- **Status:** ✅ **CONCLUÍDA** (Commits `52deeef`, `b262d82`)
- **Objetivo:** Estabelecer a física inercial de voo, o mapa procedural expansivo e a adaptação ergonômica de toque para smartphones.

### Entregáveis:
- [x] Setor procedural aberto de 4800x4800 com bordas de contenção de plasma.
- [x] Câmera dinâmica com rastreamento suave da nave da jogadora.
- [x] Mini-radar tático vetorial com cálculo de alcance e ângulo de varredura.
- [x] POIs Procedurais: Estação de Pesquisa, Destroços de Carga e Nebulosas Cósmicas.
- [x] HUD Mobile Ergonomic Cluster: Thumb-stick virtual, botão de Dash circular com cooldown, Especial Overdrive e Disparo Manual.
- [x] O Trio Inicial de Valquírias (Lyra, Selene e Vesper) com specs, design de nave e armas iniciais distintas.
- [x] Mini-avatar reativo na HUD com 3 estados (Normal, Crítico e Overdrive).
- [x] Resolução do bug de renderização de overlays no Flutter (`StackParentData`).

---

## 👾 SPRINT 2: Fórmula Vampire Survivors, Frotas & Baús
- **Status:** ✅ **CONCLUÍDA** (Commits `73f0eae`, `ba36fb6`)
- **Objetivo:** Eliminar a monotonia de combate apenas contra meteoros, inserindo IA hostil ativa, minibosses cronometrados e recompensas em baús.

### Entregáveis:
- [x] **Scout Drone:** Nave de enxame (1 a 2 tiros) com perseguição direta e fluxo constante de Stardust XP.
- [x] **Phantom Raider:** Caça veloz com máquina de estados (`stalking` $\to$ `telegraphing` com laser vermelho $\to$ `charging` a 390 px/s com Dash evasivo).
- [x] **Corvette Sniper:** Artilharia de média distância que atira orbes lentos de plasma.
- [x] **Variantes de Asteroides:** Prisma Cristalino (não divide, explode em chuva de 8 orbes de XP) e Asteroide de Magma (poça térmica persistente de dano em área).
- [x] **Void Commander (Elite Miniboss):** Flagship imponente com barra de vida flutuante, tiros em espiral e drop garantido de baú.
- [x] **Baú Cósmico & Jackpot Overlay:** Recompensa de 1x, 3x ou 5x cartas estilo caça-níquel/Vampire Survivors, aplicando upgrades automáticos de arsenal e atributos.
- [x] **Red Gem Siphon (Otimização Mobile):** Teto rígido de 60 orbes de XP em tela, concentrando excedente no orbe mais distante como Hiper-Stardust Vermelho para manter 60 FPS cravados.
- [x] **53 Testes Automatizados** cobrindo todas as mecânicas.

---

## ⚡ SPRINT 3: Super-Evoluções de Armas & Chefe Final de Setor
- **Status:** ⏳ **EM PROGRESSO**
- **Objetivo:** Implementar o auge da catarse do combate (armas evoluídas devastadoras) e o clímax da partida (batalha em fases contra o Dreadnought Leviathan).

### Entregáveis:
1. **As 4 Super-Evoluções de Arsenal (Evoluídas via Baú Cósmico no Nível Máximo):**
   - [ ] **Supernova Annihilator** (Evolução do *Pulse Blaster*): Feixe duplo acelerado de plasma ultra-denso com micro-detonações em cadeia ao atravessar inimigos.
   - [ ] **Hyperion Flak Storm** (Evolução do *Spread Cannon*): Barreira circular 360° contínua de fragmentos de flak, desintegrando projéteis hostis e enxames próximos.
   - [ ] **Absolute Zero Tachyon Beam** (Evolução do *Phase Laser*): Raio contínuo perfurante criogênico que congela e desacelera alvos em 50%.
   - [ ] **Singularity Rift Torpedo** (Evolução do *Antimatter Torpedo*): Torpedo teleguiado que, ao impactar, abre um mini buraco negro que atrai inimigos e asteroides antes do colapso gravitacional.
2. **Chefe Final de Setor: Dreadnought Leviathan (Minuto 10:00):**
   - [ ] Spawna com alarme geral do setor (`🚨 TITANIC DREADNOUGHT DETECTED`) e fechamento da zona de fuga.
   - [ ] **Fase 1 (Escolta & Baterias):** Casco blindado com 4 torres de laser orbitais e invocação de Scouts de proteção.
   - [ ] **Fase 2 (Núcleo Exposto & Danmaku):** O núcleo brilha em roxo incandescente, disparando anéis concêntricos de plasma denso.
   - [ ] **Fase 3 (Colapso Hiperbólico):** Modo desespero com investidas pesadas e rajadas contínuas de laser.
3. **Condição de Vitória da Sortie:**
   - [ ] Ao destruir o Leviathan, a run conclui como **"SECTOR SECURED // MISSION COMPLETE"**, concedendo o Baú Dourado Lendário e multiplicador de Sucata Estelar.

---

## 🛠️ SPRINT 4: Meta-Progressão, Oficina do Hangar & Economia
- **Status:** 📅 **PLANEJADA**
- **Objetivo:** Fechar o loop roguelite duradouro, permitindo que cada derrota ou vitória fortaleça a jogadora para as próximas missões.

### Entregáveis:
1. **Oficina das Valquírias (Hangar Shop):**
   - [ ] Árvore de Meta-Upgrades permanentes comprados com Sucata Estelar (*Credits*):
     - *Hull Reinforcement* (Vida inicial +1 a +3);
     - *Ion Magnet Overdrive* (Raio de coleta +15% a +60%);
     - *Hyper-Thrusters* (Velocidade e aceleração +10% a +35%);
     - *Quantum Targeting* (Taxa de Crítico inicial +5% a +20%);
     - *Lucky Star Protocol* (Chance de Baús 3x e 5x +10% a +50%).
2. **Persistência Dual (Local Cross-Sync):**
   - [ ] Salvamento automático local em JSON via `SharedPreferences`.
   - [ ] Sincronização em nuvem com o backend em Go (`POST /api/player/sync`).

---

## 💖 SPRINT 5: Galeria de Waifus, Afinidade & Micro-Balanceamento Beta
- **Status:** 📅 **PLANEJADA**
- **Objetivo:** O motor de engajamento do público de anime, polimento de som/vozes e calibração fina de parâmetros para o lançamento comercial.

### Entregáveis:
1. **Sistema de Afinidade (Bond System):**
   - [ ] Fragmentos de Memória coletados durante as runs aumentam a afinidade com a piloto em uso.
   - [ ] Desbloqueio progressivo de diálogos secretos no Hangar.
2. **Galeria de Memórias Secretas (CGs em Alta Resolução):**
   - [ ] Tela de Galeria no menu principal exibindo ilustrações widescreen (1920x1080) desbloqueadas.
   - [ ] Visualizador de arte com zoom e modo sem interface.
3. **Micro-Balanceamento da Beta:**
   - [ ] Ajuste fino do DPS de cada arma para garantir paridade estratégica.
   - [ ] Calibração da curva de dificuldade dos 10 minutos para curva de tensão perfeita.
