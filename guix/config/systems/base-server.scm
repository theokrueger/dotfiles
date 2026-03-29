;; base server system module for guix system
(define-module (config systems base-server)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (config systems base)

  #:export (%system-base-server-os
             %system-base-server-bootloader-configuration
             %system-base-server-services
             %system-base-server-packages))

(use-service-modules
  ssh
  networking
  )
(use-package-modules
  ssh
  )


;; bootloader
(define-public %system-base-server-bootloader-configuration
  (bootloader-configuration
    (inherit %system-base-bootloader-configuration)
    (terminal-outputs '(console serial))
    (serial-speed 115200)))

;; services
(define-public %system-base-server-services
  (append (list
            (service openssh-service-type)
            (service dhcpcd-service-type)

            )
    %system-base-services))

;; packages
(define-public %system-base-server-packages
  (cons*

    %system-base-packages))

;; os
(define-public %system-base-server-os
  (operating-system
    (inherit %system-base-os)
    (host-name "guix-server-base")

    (bootloader %system-base-server-bootloader-configuration)
    (kernel-arguments '("console=ttyS0,115200"))

    (packages %system-base-server-packages)
    (services %system-base-server-services)
    ))
