# Automatizando a configuração do Cisco NXOS - InterPod Network (IPN)


## Sobre o script

Este script em terraform tem a função de automatizar o processo de construção dos IPNs para o ACI MultiPod.

## Como utilizar?

Preencha a planilha conforme solicitado para gerar o arquivo variable.tf

Após o preenchimento rode o seguinte comando:

```
python3 variable.py
```
Uma vez gerado o arquivo variables.tf, basta apenas rodar o terraform.

```
terraform init
terraform plan
terraform apply -auto-approve
```

## Autor
Freitas®	
