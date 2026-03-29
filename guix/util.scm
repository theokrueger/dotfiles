;; base system module for guix system
(define-module (util)
  #:use-module (gnu services)

  #:export (
    util->create-etc-service
    )
)

(define-public (util->create-etc-service name files)
  "create a new etc-service-type for a list of filenames stored in (config etc)"
  (simple-service
    name
    etc-service-type
    (map 
      (lambda (f)
        `(,f local-file ,(string-append "./config/etc/" f))
      )
      files
    )
  )
)
