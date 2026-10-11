# Agenda Hub — ativação e verificação do backup

## Estado
Workflow preparado em `.github/workflows/agenda-backup.yml` nesta branch isolada. **Não está ativo** enquanto não for incorporado à branch padrão e as credenciais não forem configuradas.

## Segredos exigidos no GitHub Actions
- `AGENDA_BACKUP_DATABASE_URL`: URL de conexão PostgreSQL com permissão de exportação dos schemas `public` e `auth`; nunca incluir em commits.
- `AGENDA_BACKUP_PASSPHRASE`: frase aleatória forte, com pelo menos 24 caracteres, armazenada fora do repositório. Sem ela, o arquivo não pode ser restaurado.
- `AGENDA_BACKUP_RCLONE_CONFIG_B64`: configuração rclone codificada em base64, com remote `agenda_drive` restrito à pasta dedicada no Drive. Credenciais e tokens não devem ser expostos em logs.

## Verificação antes da ativação
1. Confirmar se o usuário do PostgreSQL consegue exportar `auth` e `public` sem expor credenciais.
2. Confirmar se o backup abrange os dados necessários, inclusive Auth; arquivos de Storage e segredos de projeto não estão cobertos por este workflow.
3. Executar manualmente com credenciais válidas, verificar sucesso, arquivo criptografado no Drive e integridade do download.
4. Ensaiar restauração **em banco isolado**, nunca sobre produção.
5. Somente após isso integrar o workflow à branch principal e observar a primeira execução agendada.
6. Guardar a senha de criptografia fora do Drive de backups; perder a senha significa perder acesso às cópias.

## Regras de segurança
- Não apagar dados do Supabase de produção.
- Não alterar código Flutter homologado.
- Não apagar cópias anteriores se a nova execução falhar.
- Monitorar falhas de execução no GitHub Actions.
- O mecanismo atual mantém duas cópias, mas não substitui backups históricos contra exclusões descobertas tardiamente.
