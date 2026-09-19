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


## Etapa 4 — Mão 3D com tracking procedural

A Etapa 4 usa a arquitetura Tracking Skeleton + Retargeting.

### Sem animações prontas

handvr.glb tem 0 animações. A pose é calculada continuamente pelos 21 landmarks do MediaPipe:

0 wrist
1-4 thumb
5-8 index
9-12 middle
13-16 ring
17-20 pinky

Fluxo:

MediaPipe
→ TrackingHandSkeleton
→ HandSkeletonMapper
→ Skeleton3D do handvr.glb

O mapper agora usa os nomes exatos do rig encontrado no GLB, incluindo hand_R_00 e as cadeias thumb/index/middle/ring/pinky.

Duas instâncias independentes do handvr.glb são criadas para esquerda e direita. Cada uma possui seu próprio tracking skeleton e mapper.

Os dedos recebem orientação procedural a partir das direções entre landmarks. A posição do pulso e a orientação da palma também acompanham o tracking. Não há AnimationPlayer nem animações de mão pré-gravadas.

A API de global pose override do Skeleton3D é usada apenas dentro do mapper como ponte de retargeting; ela está isolada para permitir uma futura migração para SkeletonModifier3D.

### Gate

casa.glb e handvr.glb foram verificados no repositório antes da implementação da Etapa 4.
