;; base workstation system module for nonguix system
(define-module (config systems workstation-base)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (config systems base)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)

  #:export (%system-workstation-base-os
             %system-workstation-base-bootloader-configuration
             %system-workstation-base-services
             %system-workstation-base-packages))

(use-service-modules
  networking
  )
(use-package-modules
  )

;; bootloader
(define-public %system-workstation-base-bootloader-configuration
  (bootloader-configuration
    (inherit %system-base-bootloader-configuration)
    (terminal-outputs '(gfxterm))
    ))

;; services
(define-public %system-workstation-base-services
  (append (list
            (network-manager-service-type)
            )
    %system-base-services))

;; packages
(define-public %system-workstation-base-packages
  (cons*
    network-manager
    %system-base-packages))

;; os
(define-public %system-workstation-base-os
  (operating-system
    (inherit %system-base-os)
    (host-name "guix-workstation-base")

    ;; nonguix
    (kernel linux)
    (initrd microcode-initrd)
    (firmware (list linux-firmware))

    (bootloader %system-workstation-base-bootloader-configuration)

    (packages %system-workstation-base-packages)

    ;; include nonguix substitute to services
    (services (modify-services %system-workstation-base-services
                (guix-service-type config =>
                  (guix-configuration
                    (inherit config)
                    (substitute-urls
                      (append (list "https://substitutes.nonguix.org")
                        %default-substitute-urls))
                    (authorized-keys
                      (append (list (plain-file "non-guix.pub"
                                      "(public-key (ecc (curve Ed25519) (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"
                                      ))
                        %default-authorized-guix-keys))))))
    ;; remember to run:
    ;; # guix archive --authorize < signing-key.pub
    ;; # guix system reconfigure /etc/config.scm --substitute-urls='https://ci.guix.gnu.org https://bordeaux.guix.gnu.org https://substitutes.nonguix.org'
    ))
