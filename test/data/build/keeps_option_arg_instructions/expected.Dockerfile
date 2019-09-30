ARG base_image='alpine:3.9.4'
ARG example=''

FROM "${base_image}"

ARG example
RUN if [[ -n "${example}" ]]; then \
    echo "${example}" \
  ; fi

WORKDIR /workdir
