;; template module for a guix system feature
(define-module (config home template)
  #:use-module (gnu)
  #:use-module (guix)

  #:export (%home-template)
)

(define-public %home-template
  (home-environment
    (packages (list htop))
    (services (append (list
          (service home-bash-service-type
              (home-bash-configuration
                (guix-defaults? #t)
                )
            )
        )
        %base-home-services)
      ))
  )
