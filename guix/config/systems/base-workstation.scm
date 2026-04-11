;; base workstation system module for nonguix system
(define-module (config systems base-workstation)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (config systems base)
  #:use-module (util)
  
  #:export (%system-base-workstation-os
            %system-base-workstation-bootloader-configuration
            %system-base-workstation-services
            %system-base-workstation-packages))

(use-service-modules
 networking
 )
(use-package-modules
 gnome
 admin
 )

;; bootloader
(define-public %system-base-workstation-bootloader-configuration
  (bootloader-configuration
   (inherit %system-base-bootloader-configuration)
   (terminal-outputs '(gfxterm))
   ))

;; services
(define-public %system-base-workstation-services
  (append (list
           (service network-manager-service-type)
           (service wpa-supplicant-service-type)
           )
	  %system-base-services))

;; packages
(define-public %system-base-workstation-packages
  (cons*
   network-manager
   opendoas
   %system-base-packages))

;; os
(define-public %system-base-workstation-os
  (operating-system
   (inherit %system-base-os)
   (host-name "guix-base-workstation")
   
   (bootloader %system-base-workstation-bootloader-configuration)
   
   (packages %system-base-workstation-packages)
   
   (services %system-base-workstation-services)
   )
  )
