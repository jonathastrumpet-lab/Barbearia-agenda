# Backup do Agenda Hub — estado e ativação

Este fluxo é de preparação, isolado da branch main. Não altere tabelas, dados ou a aplicação.

## Segredos necessários (GitHub Actions > Secrets and variables > Actions)
- AGENDA_BACKUP_DATABASE_URL: URI PostgreSQL do Supabase, já usada no teste de conexão.
- AGENDA_BACKUP_ENCRYPTION_KEY: senha longa, exclusiva, aleatória, com pelo menos 32 caracteres. Armazene também fora do GitHub em gerenciador de senhas seguro. Sem ela o backup não pode ser restaurado.

## Teste
1. Depois de cadastrar ambos os segredos, executar manualmente `Agenda Hub - backup seguro (preparacao)`.
2. Conferir logs, status de sucesso e artefato criptografado.
3. Baixar o artefato e testar descriptografia e restauração em banco de homologação separado, nunca sobre produção.
4. Confirmar que a exportação inclui todos os schemas e dados necessários. O fluxo atual exporta somente o schema `public` do PostgreSQL; não inclui contas do Supabase Auth, arquivos do Storage nem configurações externas.
5. Configurar destino persistente e retenção antes de ativar cron. Artefatos do GitHub expiram em 7 dias e não substituem backup no Drive.

## Atenção sobre Google Drive
Autenticação federada GitHub → Google Cloud não garante permissão para o Google Drive. É necessário conceder acesso específico a uma pasta ou usar uma integração OAuth adequada. Não colocar tokens ou chaves no código.
