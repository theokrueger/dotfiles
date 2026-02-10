;; thinkpad x1 carbon gen 3

(define-module (config systems workstation tx1cg2)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (config systems workstation-base)
)

;; (use-service-modules xyz)
;; (use-package-modules xyz)

(operating-system
  ;; basic
  (inherit %system-base-workstation-os)
  (host-name "tx1cg3")

  ;; bootloader
  (bootloader (bootloader-configuration
                (inherit %system-base-workstation-bootloader-configuration)
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
                    (type "btrfs"))

                    %base-file-systems))

  ;; packages
  (packages (append (list
                      ;xyz
                      )
              %system-base-workstation-packages))

  ;; services
  (services (append (list
                      ;(service xyz-service-type (xyz-configuration blahblah))
                      )
              %system-base-workstation-services))
  )
