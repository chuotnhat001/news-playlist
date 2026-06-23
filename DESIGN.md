# Design Tokens — News Playlist

## Colors

### Background Gradient
```
Direction: topLeft → bottomRight
Stops: [0.0, 0.35, 0.65, 1.0]
Colors: #0D0D2B, #1A1A4E, #0A2647, #144272
```

### Accent
- Primary accent: `Colors.cyanAccent` (#00DCFF)
- Accent border: rgba(0, 220, 255, 0.15)
- Accent subtle bg: rgba(0, 220, 255, 0.05–0.15)

### Text
- Primary: `Colors.white`
- Secondary: `Colors.white70` (alpha 0.7)
- Tertiary: `Colors.white` with alpha 0.5–0.6
- Disabled: `Colors.white` with alpha 0.3

### Surface
- Card background: rgba(255, 255, 255, 0.08)
- Mini player: `Theme.colorScheme.surfaceContainerHigh`

## Spacing

| Token | Value | Usage |
|-------|-------|-------|
| xs | 2dp | Text spacing, progress bar height |
| sm | 8dp | List item gaps, vertical padding |
| md | 12dp | Mini player padding |
| base | 16dp | Card padding, list padding, icon gaps |
| lg | 24dp | Progress bar label padding |
| xl | 32dp | Empty state padding, icon sizes |

## Border Radius
- Cards: 14dp
- Skeleton loaders: 4–8dp

## Glass-morphism (CategoryCard)
```
background: rgba(255, 255, 255, 0.08)
border: 1px solid rgba(0, 220, 255, 0.15)
borderRadius: 14dp
```

## Resume Card
```
background: gradient(rgba(0, 220, 255, 0.15) → rgba(0, 220, 255, 0.05))
border: 1px solid rgba(0, 220, 255, 0.3)
borderRadius: 14dp
```

## Touch Targets
- Minimum: 56dp × 56dp (driving context)
- Category card: 76dp height × full width
- Play button: 64dp icon
- Skip buttons: 36dp icon, 56dp touch target
- Mini player play: 56dp minimum

## Typography
- System: Flutter Material 3 default (no custom font)
- Category title: `titleMedium`, white
- Subtitle: `bodySmall`, white with alpha
- Mini player title: `bodyMedium`
- Mini player source: `bodySmall`, `onSurfaceVariant`

## Shadows
- Mini player: `BoxShadow(black alpha 0.1, blur 4, offset (0, -1))`

## Icon Sizes
- Category icon: 32dp
- Chevron: 24dp (default)
- Music note (mini player): 24dp
- Player controls play/pause: 64dp
- Player controls skip: 36dp
- Swipe action icons: 22dp
