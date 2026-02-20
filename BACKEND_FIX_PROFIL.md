# Correction Backend - Erreur "Profil non trouvé"

## Problème
L'erreur `Profil non trouvé pour l'utilisateur: 698e498526541b28f95b945f` indique que le backend ne trouve pas le profil du centre d'analyse lors de l'appel à `/lab/profile`.

## Solutions à implémenter côté Backend

### 1. Vérifier la création automatique du profil lors de l'inscription

**Dans `auth.service.ts` ou le service d'inscription :**

```typescript
async register(registerDto: RegisterDto) {
  // 1. Créer l'utilisateur
  const user = await this.usersService.create(registerDto);
  
  // 2. Si le rôle est "centreAnalyse", créer automatiquement le profil
  if (user.role === UserRole.CENTRE_ANALYSE) {
    try {
      await this.profilesService.createLabProfile({
        userId: user._id,
        centreName: registerDto.centreName,
        categorie: registerDto.categorie,
        localisation: registerDto.localisation,
        phone: registerDto.phone,
        email: registerDto.email,
        // ... autres champs
      });
    } catch (error) {
      // Logger l'erreur mais ne pas faire échouer l'inscription
      console.error('Erreur création profil lab:', error);
    }
  }
  
  return user;
}
```

### 2. Modifier `/lab/profile` pour créer le profil s'il n'existe pas

**Dans `lab.controller.ts` ou le contrôleur du profil lab :**

```typescript
@Get('profile')
@UseGuards(JwtAuthGuard)
async getLabProfile(@Request() req) {
  const userId = req.user.id;
  
  // Essayer de récupérer le profil
  let profile = await this.profilesService.findLabProfileByUserId(userId);
  
  // Si le profil n'existe pas, le créer avec les données de l'utilisateur
  if (!profile) {
    const user = await this.usersService.findById(userId);
    
    // Créer le profil avec les données de base de l'utilisateur
    profile = await this.profilesService.createLabProfile({
      userId: user._id,
      centreName: user.centreName || 'Centre d\'Analyses',
      email: user.email,
      phone: user.phone,
      // ... autres champs par défaut
    });
  }
  
  return profile;
}
```

### 3. Alternative : Créer un endpoint de migration/initialisation

**Créer un endpoint pour initialiser le profil manquant :**

```typescript
@Post('profile/init')
@UseGuards(JwtAuthGuard)
async initLabProfile(@Request() req) {
  const userId = req.user.id;
  
  // Vérifier si le profil existe déjà
  const existingProfile = await this.profilesService.findLabProfileByUserId(userId);
  if (existingProfile) {
    return existingProfile;
  }
  
  // Récupérer les données de l'utilisateur
  const user = await this.usersService.findById(userId);
  
  // Créer le profil
  const profile = await this.profilesService.createLabProfile({
    userId: user._id,
    centreName: user.centreName || 'Centre d\'Analyses',
    email: user.email,
    phone: user.phone,
    // ... autres champs
  });
  
  return profile;
}
```

### 4. Vérifier le schéma du profil Lab

**Dans le schéma MongoDB du profil Lab :**

Assurez-vous que le schéma a bien un champ `userId` qui référence l'utilisateur :

```typescript
@Schema()
export class LabProfile {
  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true })
  userId: mongoose.Types.ObjectId;
  
  @Prop()
  centreName?: string;
  
  @Prop()
  categorie?: string[];
  
  // ... autres champs
}
```

### 5. Gérer les erreurs gracieusement

**Dans le contrôleur, ajouter une gestion d'erreur :**

```typescript
@Get('profile')
@UseGuards(JwtAuthGuard)
async getLabProfile(@Request() req) {
  try {
    const userId = req.user.id;
    const profile = await this.profilesService.findLabProfileByUserId(userId);
    
    if (!profile) {
      // Retourner une réponse avec un message indiquant que le profil doit être créé
      return {
        message: 'Profil non trouvé. Veuillez compléter votre profil.',
        needsInit: true,
        userId: userId
      };
    }
    
    return profile;
  } catch (error) {
    throw new HttpException(
      'Erreur lors de la récupération du profil',
      HttpStatus.INTERNAL_SERVER_ERROR
    );
  }
}
```

## Solution recommandée

**La meilleure approche est la solution #2** : Modifier `/lab/profile` pour créer automatiquement le profil s'il n'existe pas. Cela garantit que :

1. ✅ Le profil est toujours disponible après connexion
2. ✅ Pas besoin de migration manuelle
3. ✅ Fonctionne pour les utilisateurs existants et nouveaux
4. ✅ Expérience utilisateur fluide

## Test

Après implémentation, tester avec :

1. Un utilisateur existant sans profil → Le profil doit être créé automatiquement
2. Un nouvel utilisateur → Le profil doit être créé lors de l'inscription
3. Un utilisateur avec profil existant → Le profil existant doit être retourné
