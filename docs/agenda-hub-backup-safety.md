# Agenda Hub — plano de backup seguro (isolado)

Status: PREPARAÇÃO. Não há backup concluído.

Projeto Supabase: drvaacngbtnjxdeakgnn
Repositório: jonathastrumpet-lab/Barbearia-agenda
Pasta Drive existente: https://drive.google.com/drive/folders/18MxCp3f52drMtmcZkC8ocnHnlCkYJA2m

## Requisitos para ativação
- Gerar backup consistente com pg_dump (formato custom) e confirmar integridade.
- Criptografar antes de transferir; chave em segredo separado, nunca no código.
- Integrar autenticação Google Drive para execução NÃO INTERATIVA, com permissão mínima à pasta.
- Enviar como arquivo novo com identificador único; validar tamanho e checksum no Drive.
- Somente após validação, aplicar retenção segura de pelo menos duas versões.
- Ensaiar restauração em ambiente isolado, nunca sobre produção.
- Proteger usuários, dados de auth, storage, roles e configurações que não sejam capturados integralmente por pg_dump.
- Registrar falhas e notificar sem revelar credenciais.
- Fazer snapshot adicional antes de deploy, sem bloquear nem modificar builds atuais.

Não adicionar senha do banco, tokens ou dumps ao GitHub. Não modificar o app homologado.
