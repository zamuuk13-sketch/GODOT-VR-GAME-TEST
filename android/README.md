# Android integration

## Etapa 3 — Hand Tracking

A fundação de hand tracking usa a câmera física do Android através de CameraServer/CameraFeed e mantém um HandTrackingProvider separado da lógica do jogo.

Fluxo:

Android rear camera
→ camera frames
→ hand-tracking provider
→ left/right hand landmarks
→ Godot gesture/game logic

O processamento de landmarks deve ser local no aparelho.

### Meta de desempenho

O alvo do sistema de tracking é 60 atualizações por segundo. O HUD mede a taxa real recebida pelo provider; isso é separado do FPS de renderização do jogo.

### Adaptador nativo

A camada HandTrackingProvider é independente do fornecedor. O adaptador Android de visão deverá conectar uma biblioteca de hand tracking local ao provider, sem alterar a lógica de gameplay.

Godot suporta Android plugins para integrar bibliotecas do ecossistema Android, e CameraServer/CameraFeed fornece acesso às câmeras físicas em Android.

### Gate dos modelos

A Etapa 3 não depende de casa.glb ou handvr.glb.

Antes de avançar para a etapa de mão virtual, conferir res://modelos/ e exigir:

- casa.glb
- handvr.glb


## Etapa 4 — Mão 3D

A mão virtual usa `res://modelos/handvr.glb`.

O sistema:
- instancia uma mão para cada lado detectado;
- procura automaticamente um `Skeleton3D` dentro do GLB;
- associa os dedos aos 21 landmarks do MediaPipe;
- aplica a direção dos segmentos aos ossos;
- suaviza posição e rotação;
- espelha a mão direita;
- mantém a mão posicionada no espaço relativo à câmera VR.

O mapeamento suporta nomes comuns de ossos como wrist/palm/hand, thumb, index/pointer, middle, ring e pinky/little, com níveis proximal/intermediate/distal ou sufixos numéricos.

A etapa depende de `handvr.glb` ter um `Skeleton3D` com ossos dos dedos. O sistema não cria um esqueleto artificial nem altera a malha do modelo.
