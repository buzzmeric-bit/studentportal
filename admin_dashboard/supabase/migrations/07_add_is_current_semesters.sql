-- Add is_current to semesters to track current semester per school
alter table public.semesters
  add column if not exists is_current boolean not null default false;

-- Ensure only one current semester per school via partial unique index
create unique index if not exists semesters_one_current_per_school
  on public.semesters (school_id)
  where is_current;
