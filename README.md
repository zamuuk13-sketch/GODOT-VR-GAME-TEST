# Godot VR Game Test

Etapa 1 — Fundação do projeto.

## Estrutura

- `modelos/casa.glb` — mapa da casa, colocado pelo usuário.
- `modelos/handvr.glb` — modelo 3D da mão, colocado pelo usuário.
- `scenes/main.tscn` — cena principal.
- `scenes/player.tscn` — player base.
- `scenes/spawn_point.tscn` — ponto inicial configurável.
- `scripts/player/player.gd` — base do player.
- `scripts/player/spawn_point.gd` — configuração do spawn.

## Modelos

Coloque os dois arquivos nesta pasta:

```
modelos/casa.glb
modelos/handvr.glb
```

A cena da casa está preparada para usar `casa.glb` quando ele existir. O projeto não depende de assets binários para abrir e editar a fundação.

## Próximas etapas

1. Fundação
2. Head tracking + giroscópio
3. Hand tracking
4. Mão 3D
5. Teleporte
6. Integração e otimização Android
