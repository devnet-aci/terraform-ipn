import openpyxl
from jinja2 import Environment, FileSystemLoader

# Carregar o arquivo Excel
workbook = openpyxl.load_workbook('ipn.xlsx')
sheet = workbook.active

# Extrair os dados da planilha para um dicionário
data = {}
for row in sheet.iter_rows(min_row=2, values_only=True):
    chave, valor = row
    data[chave] = valor

# Carregar o template Jinja2
env = Environment(loader=FileSystemLoader('.'))
template = env.get_template('template.txt')

# Renderizar o template com os dados
variables = template.render(data)

# Gerando variable.tf para ser usado no Terraform
with open('variable.tf', 'w') as f:
    f.write(variables)
