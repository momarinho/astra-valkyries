# 🎨 Pipeline de Arte, Personagens e Idioma (MVP)

**Projeto:** *Astra Valkyries: Void Protocol*  
**Repositório:** `momarinho/astra-valkyries` (Comercial / Privado)  
**Versão:** 1.0  
**Data:** 05/11/2026  

---

## 🌐 1. Diretriz de Idioma Primário (Steam & Global Market)

> [!IMPORTANT]
> **O jogo será desenvolvido e lançado PRIMARIAMENTE EM INGLÊS (EN).**

- **Justificativa Comercial:** O maior volume de vendas e listas de desejos (*wishlists*) na Steam para jogos do gênero *Bullet Heaven / Anime Action Roguelite* provém dos Estados Unidos, Europa e Ásia (jogadores internacionais consom rotineiramente jogos em inglês).
- **Escopo Inicial (Launch 1.0):**
  - Toda a Interface do Usuário (UI), nomes de armas, sinergias, cartas, tutoriais e diálogos de rádio estarão exclusivamente em **Inglês**.
  - A voz das personagens (*Voice Grunts / Battle Callouts*) seguirá o padrão clássico em **Japonês (JA)** ou **Inglês (EN)** para manter a autenticidade do estilo anime.
- **Localizações Futuras (Pós-lançamento / Updates):**
  - Português Brasileiro (PT-BR).
  - Japonês (JA).
  - Chinês Simplificado (ZH-CN).

---

## 🎯 2. Posicionamento de Design: Pilotos & Arquétipos Sci-Fi

- **Demografia Principal:** Jogadores de roguelites frenéticos e fãs de ficção científica espacial e anime de ação (*Gundam, Macross, Evangelion, Hades, Nova Drift*).
- **Diretrizes de Design dos Pilotos:**
  - O elenco principal foca em **Pilotos de Elite de Caças Espaciais** com forte personalidade, trajes táticos funcionais (*pilot suits / mecha armor*) e sinergia mecânica profunda com suas respectivas naves.
  - Arquétipos variados: a vanguardista veloz e destemida (Lyra), a estrategista quântica analítica (Selene), a especialista rebelde em armamento pesado (Vesper) e a espadachim taquiônica disciplinada (KBR-01 / Kaede).

---

## 🖼️ 3. As 4 Camadas de Aparição das Personagens no Jogo

```mermaid
graph TD
    A["1. HUD Reativo em Combate"] -->|Retrato animado com reações a dano e combos| Gameplay["Gameplay Frenética (Espaço 2D)"]
    B["2. Rádio Holográfico Visual Novel"] -->|Diálogos com o Comandante no início de ondas| Gameplay
    Gameplay -->|Coleta de Fragmentos Cósmicos| C["3. Hangar & Lounge da Base"]
    C -->|Sistema de Afinidade, Diálogos e Telemetria| D["4. Galeria de Dossiês Táticos & Arquivos de Missão"]
```

### 3.1. Mini-Avatar Reativo na HUD (Durante a Partida)
- Localizado no canto superior/inferior da tela ao lado das barras de escudo e casco.
- Expressões dinâmicas que reagem ao estado de combate:
  1. **Neutra / Foco:** Pilotagem normal e concentração em alvo.
  2. **Dano Crítico / Alerta de Casco:** Expressão de alerta máximo, faíscas no visor holográfico e áudio tático de aviso.
  3. **Ataque Supremo / Especial:** Olhar triunfante com animação de corte de tela estilo anime (*Cut-in*).

### 3.2. Transmissão de Rádio Holográfica (Visual Novel Box)
- Caixas de diálogo semi-translúcidas futuristas que surgem na tela antes do spawn de chefes ou ao ingressar em um novo setor.
- Sprite em meia-altura (*half-body*) das pilotos se comunicando diretamente com o jogador ("O Comandante").

### 3.3. Hangar & Lounge das Valkyries (Meta-Game)
- Tela principal fora das partidas onde o jogador interage com o sprite de corpo inteiro (*full-body*) da piloto selecionada.
- **Sistema de Afinidade (Bond System):** Missões concluídas e núcleos de memória elevam o nível de sincronia tática, liberando novos diálogos de camaradagem, histórico de serviço e bônus de combate.

### 3.4. Galeria de Dossiês Táticos & Arquivos de Missão
- Ilustrações completas de tela cheia (1280x720 / 1920x1080) desbloqueadas ao cumprir recordes ou elevar o nível de afinidade.
- Relatórios detalhados de reconhecimento de setores, especificações de armas pesadas, calibração de propulsores e eventos cósmicos marcantes.

---

## 👥 4. O Trio Inicial do MVP (As 3 Primeiras Valkyries)

| Personagem | Título | Visual / Cabelo | Personalidade / Tropo | Nave & Arma Inicial |
| :--- | :--- | :--- | :--- | :--- |
| **Lyra** | *Solar Vanguard* | Ruiva/coral, mechas dinâmicas, olhos âmbar, headset mecha-neko branco e exo-traje cibernético | Enérgica, ousada, confiante, adora velocidade | Interceptador veloz *AV-01 Sol Blaze* com *Twin Vulcan Plasma* |
| **Selene** | *Void Tactician* | Prateado/Azul gelo longo, visor holográfico | Kuudere fria, analítica, fala com calma calculada | Fragata tática azul com *Phase Laser Piercing Beam* |
| **Vesper** | *Dread Renegade* | Cabelo escuro curto com mechas magenta (Tomboy) | Rebelde, provocante, debochada, adora explosões | Caça furtivo preto com *Antimatter Spread & Bombs* |

---

## 📋 5. Checklist de Assets Necessários para o MVP

Para cada uma das 3 personagens, os seguintes arquivos deverão ser gerados e organizados na pasta `assets/art/valkyries/`:

### Por Personagem (Exemplo: `lyra/`):
- [x] `hud_neutral.png` (512x512, PNG transparente, busto)
- [x] `hud_damaged.png` (512x512, PNG transparente, busto com alerta de dano tático)
- [x] `hud_ultimate.png` (512x512, PNG transparente, busto em ângulo triunfante)
- [x] `hangar_fullbody.png` (1024x1536, PNG transparente, corpo inteiro com traje de piloto)
- [x] `tactical_log_1.jpg` (1280x720, 16:9 Widescreen, dossiê tático de setor)
- [x] `tactical_log_2.jpg` (1280x720, 16:9 Widescreen, dossiê supremo de combate)

---

## 🛠️ 6. Guia Prático de Geração Visual

### 6.1. Ferramentas Recomendadas
1. **SeaArt.ai / Leonardo.ai / Midjourney (Modo `--niji 6`):**
   - Excelente aderência a trajes futuristas, estética mecha e expressões faciais expressivas.
2. **Stable Diffusion Local (ComfyUI / WebUI Forge):**
   - Modelos: *Illustrious-XL* ou checkpoints focados em anime sci-fi e arte conceitual vetorial.

### 6.2. Estrutura Base de Prompt para Sprites das Valkyries

#### Template de Prompt (Hangar & HUD):
```text
masterpiece, best quality, ultra-detailed, 1girl, [NOME/CABELO], anime style, futuristic sci-fi pilot suit, mechanical armor plating, neon glowing accents, highly detailed eyes, dynamic lighting, heroic expression, transparent background, upper body portrait
```

#### Template para Alerta de Combate (HUD Dano):
```text
masterpiece, best quality, 1girl, [NOME], scuffed futuristic pilot suit, warning sparks, intense focus, defiant expression, high-threat alert, upper body, transparent background
```

#### Template para a Nave Espacial (Top-Down):
```text
masterpiece, sci-fi spacecraft, top-down view, centered, symmetrical 2d game asset, futuristic fighter spaceship, sleek neon wings, clean vector line art, isolated on black background, 4k
```

### 6.3. Remoção de Fundo dos Sprites
Para deixar os sprites com fundo transparente perfeito sem bordas brancas:
- Ferramenta de linha de comando: `rembg` (Python)
  ```bash
  pip install rembg
  rembg i entrada.png saida.png
  ```
- Ou via ferramentas web gratuitas como Photoroom / Adobe Express.

---
