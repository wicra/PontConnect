## PontConnect - Projet 150h

### Description

Le projet **"PontConnect"** est un projet de fin d'année du BTS CIEL Informatique & Réseaux, visant à appliquer les connaissances acquises en développement systèmes et maintenance informatique. Il s'agit d'une **application mobile** permettant aux propriétaires de bateaux de **réserver des créneaux d'ouverture de ponts**, optimisant ainsi la navigation fluviale. Le projet inclut également des fonctionnalités de **domotique** pour la gestion à distance des ponts et un **backend robuste en PHP**, avec une base de données pour le suivi des réservations et des données de trafic.

### Fonctionnalités

- **Réservation de créneaux** : Les capitaines peuvent réserver des créneaux d'ouverture de pont en fonction de la disponibilité via l'application mobile.
- **Gestion des ponts à distance** : Les opérateurs peuvent contrôler l'ouverture et la fermeture des ponts grâce à une interface de domotique intégrée.
- **Visualisation des données des ponts** : L'application permet de consulter les données des capteurs associés aux ponts, telles que la température, la qualité de l'eau et le niveau d'eau.
- **Notifications en temps réel** : Les utilisateurs reçoivent des notifications concernant les changements de statut des ponts, les confirmations de réservation, et plus encore.

### Technologies utilisées

- **Monday.com** : Utilisé pour la gestion et la planification du projet.
- **Flutter & Dart** : Framework et langage pour le développement de l'application mobile.
- **PHP & MySQL** : Utilisés pour le développement de l'API REST et la gestion de la base de données pour le backend.
- **Domotique** : Intégration de capteurs pour la gestion des ponts, incluant :
    - **Température** (pour détecter si l'eau est gelée)
    - **Qualité de l'eau** (analyse de la pollution)
    - **Niveau d'eau** (bas ou haut)
    - **LoRa** avec des modules **LilyGo ESP** pour la communication sans fil

### Objectifs

- Améliorer l'efficacité de la gestion des ponts mobiles.
- Réduire les temps d'attente pour les bateaux et éviter la saturation des parkings de bateaux sur le port.
- Optimiser le trafic fluvial.
- Faciliter l'accès aux données liées aux ponts.
- Fournir une plateforme conviviale et intuitive pour les utilisateurs.
