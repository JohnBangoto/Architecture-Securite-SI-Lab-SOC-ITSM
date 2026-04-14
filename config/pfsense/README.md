# 🛡️ pfSense – Cœur de l'Infrastructure et Sécurité Périmétrale

## 🎯 Rôle du Système
Le pare-feu **pfSense CE 2.7.x** constitue la clé de voûte de la segmentation du laboratoire. Il assure la séparation étanche entre les flux utilisateurs et les outils de supervision tout en centralisant la sécurité du périmètre.

### Fonctions Clés :
- **Segmentation Réseau** : Isolation physique et logique de la zone DATA.
- **Filtrage "Default Deny"** : Politique de sécurité stricte interdisant tout flux non explicitement autorisé.
- **Relais DHCP** : Transmission des requêtes d'adressage vers le contrôleur de domaine **DC25**.
- **Durcissement WAN** : Protection contre l'usurpation d'IP (Anti-spoofing) et les réseaux non routables.

## 🗺️ Topologie Réseau Mise à Jour
L'infrastructure repose sur un adressage de classe B segmenté comme suit :


       [ INTERNET / WAN ]
               │
         (em0 - DHCP)
               │
        [  pfSense FW  ]
               │
         [ DATA_ZONE ]
          (em1 - .126)
               │
         ├── DC25 (.10)
         └── Clients Win