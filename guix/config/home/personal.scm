;; home environment for machines i personally use for general usage
(define-module (config home personal)
  #:use-module (gnu)
  #:use-module (guix)
)

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
