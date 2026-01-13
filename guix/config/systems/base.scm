;; base system module for guix system

(define-module (config systems base)
  #:use-module (gnu)
  #:use-module (guix)

  #:use-module (gnu system nss)

  #:export (%system-base-os
             %system-base-bootloader-configuration
             %system-base-services
             %system-base-packages))

(use-service-modules
  ssh
  avahi
  mcron
  )
(use-package-modules
  base
  idutils
  ntp
  guile-xyz
  ssh
  admin
  kfbwypeukg
  lsof
  bash
  emacs
  version-control
  )

;; base cronjobs
(define gc-job
  ;; collect garbage 5 minutes after midnight every sunday
  #~(job "5 0 * * 0" "guix gc -F 1G"))

;; bootloader
(define-public %system-base-bootloader-configuration
  (bootloader-configuration
      (targets '("/dev/vda"))
      (bootloader grub-efi-bootloader)
      (keyboard-layout keyboard-layout)
      (terminal-outputs '(console serial))
      (serial-speed 115200)))

;; services
(define-public %system-base-services
  (append (list
            (service unattended-upgrade-service-type
              (unattended-upgrade-configuration
                (schedule "30 01 * * 0")
                (services-to-restart '(mcron ntp avahi))))
            (service openssh-service-type)
            (service dhcpcd-service-type)
            (service ntp-service-type)
            (service avahi-service-type)
            (simple-service 'base-cron-jobs
              mcron-service-type
              (list
                gc-job))
            )
    %base-services))

;; packages
(define-public %system-base-packages
  (cons*
    ;; daemon
    ntp mcron openssh
    ;; sys
    htop lsof bash-completion
    ;; text
    emacs
    ;; cli
    fastfetch rename tree
    ;; dev
    git git-lfs

    %base-packages))

;; os
(define-public %system-base-os
  (operating-system
    (host-name "guix-base")
    (timezone "America/New_York")
    (locale "en_US.utf8")
    (keyboard-layout (keyboard-layout "us" "altgr-intl"))

    (bootloader %system-base-bootloader-configuration)
    (kernel-arguments '("console=ttyS0,115200"))

    (swap-devices (list (swap-space
                          (target (file-system-label "SWAP")))
                    ))

    (file-systems (cons (file-system
                          (device (file-system-label "ROOT"))
                          (mount-point "/")
                          (type "btrfs"))
                    %base-file-systems))

    (users (cons (user-account
                   (name "me")
                   (group "users")
                   (supplementary-groups '("wheel"))
                   (home-directory "/home/me"))
             %base-user-accounts))

    (packages %system-base-packages)
    (services %system-base-services)
    ))
