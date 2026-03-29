;; homelab raid1 nas with 2x10tb hdd on pentium j5040
(define-module (config systems servers nastty)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (config systems base-server)
)

(use-service-modules networking nfs)
(use-package-modules linux)

(operating-system
  ;; basic
  (inherit %system-base-server-os)
  (host-name "nastty")

  ;; bootloader
  (bootloader
    (bootloader-configuration
      (inherit %system-base-server-bootloader-configuration)
      (targets (list "/boot/efi"))
    )
  )

  ;; filesystems
  (swap-devices
    (list
      (swap-space (target (file-system-label "SWAP")))
    )
  )

  (file-systems 
    (cons*
      (file-system
        (mount-point "/boot/efi")
        (device (file-system-label "EFI"))
        (type "vfat")
      )
      (file-system
        (device (file-system-label "ROOT"))
        (mount-point "/")
        (type "ext4")
      )
      ;; RAID1 HDD on /storage
      (file-system
        (device (file-system-label "NASTTY"))
        (mount-point "/storage")
        (type "btrfs")
        (options "compress=zstd:3,space_cache=v2")
      )
      %base-file-systems
    )
  )

  ;; packages
  (packages %system-base-server-packages)

  ;; services
  (services
    (append
      (list
        (service nfs-service-type
          (nfs-configuration
            (exports
              '(
                 ("/storage" "*.local(rw,async,no_subtree_check) 192.168.*/24(rw,async,no_subtree_check)")
               )
             )
           )
        )
                      ;; TODO firewall
                      ;; (service nftables-service-type
                      ;;   (nftables-configuration
                      ;;     (ruleset (mixed-text-file "nftables.conf"
                      ;;                ""
                      ;;                ))
                      ;;     ))
      )
      %system-base-server-services
    )
  )
)
