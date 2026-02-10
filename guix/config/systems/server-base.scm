;; base server system module for guix system
(define-module (config systems server-base)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (config systems base)

  #:export (%system-server-base-os
             %system-server-base-bootloader-configuration
             %system-server-base-services
             %system-server-base-packages))

(use-service-modules
  ssh
  )
(use-package-modules
  ssh
  )


;; bootloader
(define-public %system-server-base-bootloader-configuration
  (bootloader-configuration
    (inherit %system-base-bootloader-configuration)
    (terminal-outputs '(console serial))
    (serial-speed 115200)))

;; services
(define-public %system-server-base-services
  (append (list
            (service openssh-service-type)
            (service dhcpcd-service-type)

            )
    %system-base-services))

;; packages
(define-public %system-server-base-packages
  (cons*

    %system-base-packages))

;; os
(define-public %system-server-base-os
  (operating-system
    (inherit %system-base-os)
    (host-name "guix-server-base")

    (bootloader %system-server-base-bootloader-configuration)
    (kernel-arguments '("console=ttyS0,115200"))

    (packages %system-server-base-packages)
    (services %system-server-base-services)
    ))
