-- Duas peças pedidas para as demandas:
--
-- 1) Tarefas fixas: um catálogo pequeno de categorias (Otimização, Report,
--    Implementação, UTM, Planejamento, Tracking, Proposta comercial, Análise,
--    Configuração, Site, CRM) que a equipe escolhe ao criar a demanda, e que
--    aparece como rótulo antes do nome dela. Fica em tabela, não em código
--    como o catálogo de plataformas do double check, porque aqui a pedida
--    explícita foi ter uma tela para incluir/editar sem depender de deploy.
--
--    A demanda guarda o NOME do tipo, não o id: se alguém renomear ou apagar
--    um tipo do catálogo depois, as demandas que já usavam aquele rótulo
--    continuam mostrando ele. O catálogo é só a lista de opções, não a fonte
--    de verdade do que já foi escolhido.
--
-- 2) Double check com responsável e prazo, e uma etapa que trava depois de
--    pronta: hoje cada item da checklist é só sim/não, sem responsável (isso
--    foi decisão de outra mudança, para não estourar a altura da linha). O
--    pedido agora é um campo ÚNICO por demanda, antes da lista inteira, e que
--    o nome pare de poder ser trocado assim que a checklist terminar — é a
--    assinatura de quem fez a conferência, não deve ser reescrita depois.

create table if not exists public.task_tipos (
  id         uuid primary key default gen_random_uuid(),
  nome       text not null,
  ordem      integer not null default 0,
  criado_em  timestamptz not null default now()
);

create unique index if not exists task_tipos_nome_uidx on public.task_tipos (nome);

alter table public.task_tipos enable row level security;

create policy task_tipos_select on public.task_tipos
  for select to authenticated using (true);

create policy task_tipos_admin_write on public.task_tipos
  for all to authenticated using (is_admin()) with check (is_admin());

insert into public.task_tipos (nome, ordem) values
  ('Otimização', 1),
  ('Report', 2),
  ('Implementação', 3),
  ('UTM', 4),
  ('Planejamento', 5),
  ('Tracking', 6),
  ('Proposta comercial', 7),
  ('Análise', 8),
  ('Configuração', 9),
  ('Site', 10),
  ('CRM', 11)
on conflict (nome) do nothing;

alter table public.tasks add column if not exists tipo text;
comment on column public.tasks.tipo is
  'Rótulo da tarefa fixa escolhida no catálogo task_tipos, guardado como texto (não FK) para sobreviver a renomeação/exclusão do catálogo. Nulo = sem tipo.';

alter table public.tasks add column if not exists dc_responsavel text;
alter table public.tasks add column if not exists dc_prazo date;
comment on column public.tasks.dc_responsavel is
  'Responsável pela etapa de double check desta demanda. A tela trava este campo (só leitura) assim que a checklist de double check é concluída inteira — o nome deixa de poder ser trocado.';
comment on column public.tasks.dc_prazo is
  'Prazo combinado para a etapa de double check desta demanda.';
