FROM python:3.7.6-buster

MAINTAINER Jose A Alvarado "jose.alvarado-guzman@neo4j.com"

LABEL name="Data Science Toolbox" \ 
      version=1.0

ARG USER=datascience
ARG HOME=/home/${USER}
ARG R_LIBS=/${HOME}/.R_Libs

ENV WORKON_HOME=${HOME}/.virtualenvs \
    PROJECT_HOME=${HOME}/Development \
    TINI_VERSION=v0.6.0

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini

COPY . ${HOME}

RUN apt-get update \
    && apt-get install -y vim git r-base \
    && pip install virtualenv virtualenvwrapper jupyter \
    && groupadd -r -g 2200 ${USER} \
    && useradd -r -g ${USER} -u 2200 ${USER} \
    && chmod +x /usr/bin/tini \
    && mkdir ${PROJECT_HOME} \
    && Rscript ${HOME}/install_r_notebook_pakages.R \
    && mkdir ${R_LIBS} \
    && chown -R ${USER}:${USER} ${HOME} \
    && rm -rf /tmp/* \
    && rm -rf /var/lib/apt/lists/*

USER ${USER}

WORKDIR ${HOME}

RUN echo "source /usr/local/bin/virtualenvwrapper.sh" >> ${HOME}/.bashrc \
    && echo 'gpip(){\n\
        PIP_REQUIRE_VIRTUALENV=""\n\
        pip "$@"\n\
        PIP_REQUIRE_VIRTUALENV=true\n\
    }' >> ${HOME}/.bashrc \
    && jupyter notebook --generate-config \
    && python ${HOME}/set_notebook_password.py >> ${HOME}/.jupyter/jupyter_notebook_config.py \
    && rm ${HOME}/set_notebook_password.py \
    && rm ${HOME}/install_r_notebook_pakages.R

ENV PIP_REQUIRE_VIRTUALENV="true"

RUN /bin/bash -c "source /usr/local/bin/virtualenvwrapper.sh && mkproject DS_Training && pip install -r ${HOME}/requirements.txt && ipython kernel install --user --name=Python3_DS_Training && mv ${HOME}/fuel_efficiency_analysis_using_R.ipynb . && mv ${HOME}/fuel_efficiency_analysis_using_python.ipynb . && mv ${HOME}/housing_price_ml.ipynb . && mv ${HOME}/transaction_fraud_classifier.ipynb ."

EXPOSE 8888

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0"]
