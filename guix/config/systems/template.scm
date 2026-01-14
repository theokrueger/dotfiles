;; template for spinning up new systems using base config

(define-module (config systems template)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (config systems base)
)

;; (use-service-modules xyz)
;; (use-package-modules xyz)

(operating-system
  ;; basic
  (inherit %system-base-os)
  (host-name "template")

  ;; bootloader
  (bootloader (bootloader-configuration
                (inherit %system-base-bootloader-configuration)
                ))

  ;; filesystems
  (swap-devices (list (swap-space
                        (target (file-system-label "SWAP")))
                  ))

  (file-systems (cons*
                  (file-system
                    (mount-point "/boot/efi")
                    (device (file-system-label "EFI"))
                    (type "vfat"))
                  (file-system
                    (device (file-system-label "ROOT"))
                    (mount-point "/")
                    (type "ext4"))

                    %base-file-systems))

  ;; packages
  (packages (append (list
                      ;xyz
                      )
              %system-base-packages))

  ;; services
  (services (append (list
                      ;(service xyz-service-type (xyz-configuration blahblah))
                      )
              %system-base-services))
  )
