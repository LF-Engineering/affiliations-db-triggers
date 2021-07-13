-- tables
-- changes_cache
drop table if exists changes_cache;
create table changes_cache(
  ky varchar(16) not null,
  value varchar(40) not null,
  updated_at datetime(6) not null default now(),
  status varchar(16) not null,
  primary key(ky, value, status)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_unicode_520_ci;

-- changes_cache indices
alter table changes_cache add index changes_cache_ky_idx(ky);
alter table changes_cache add index changes_cache_value_idx(value);
alter table changes_cache add index changes_cache_updated_at_idx(updated_at);
alter table changes_cache add index changes_cache_status_idx(status);

-- triggers
delimiter $

-- identities
drop trigger if exists identities_after_insert_trigger;
create trigger identities_after_insert_trigger after insert on identities
for each row begin
  insert into changes_cache(ky, value, status) values('profile', new.uuid, 'pending') on duplicate key update updated_at = now();
  insert into changes_cache(ky, value, status) values('identity', new.id, 'pending') on duplicate key update updated_at = now();
end$

drop trigger if exists identities_after_update_trigger;
create trigger identities_after_update_trigger after update on identities
for each row begin
  if old.source != new.source or not(old.name <=> new.name) or not(old.email <=> new.email) or not(old.username <=> new.username) or not(old.uuid <=> new.uuid) then
    insert into changes_cache(ky, value, status) values('profile', new.uuid, 'pending') on duplicate key update updated_at = now();
    if not(old.uuid <=> new.uuid) then
      insert into changes_cache(ky, value, status) values('profile', old.uuid, 'pending') on duplicate key update updated_at = now();
    end if;
    insert into changes_cache(ky, value, status) values('identity', new.id, 'pending') on duplicate key update updated_at = now();
  end if;
end$

drop trigger if exists identities_after_delete_trigger;
create trigger identities_after_delete_trigger after delete on identities
for each row begin
  insert into changes_cache(ky, value, status) values('profile', old.uuid, 'pending') on duplicate key update updated_at = now();
  insert into changes_cache(ky, value, status) values('identity', old.id, 'pending') on duplicate key update updated_at = now();
end$

-- profiles
drop trigger if exists profiles_after_insert_trigger;
create trigger profiles_after_insert_trigger after insert on profiles
for each row begin
  insert into changes_cache(ky, value, status) values('profile', new.uuid, 'pending') on duplicate key update updated_at = now();
end$

drop trigger if exists profiles_after_update_trigger;
create trigger profiles_after_update_trigger after update on profiles
for each row begin
  if not(old.name <=> new.name) or not(old.email <=> new.email) or not(old.gender <=> new.gender) or not(old.gender_acc <=> new.gender_acc) or not(old.is_bot <=> new.is_bot) or not(old.country_code <=> new.country_code) then 
    insert into changes_cache(ky, value, status) values('profile', new.uuid, 'pending') on duplicate key update updated_at = now();
  end if;
end$

drop trigger if exists profiles_after_delete_trigger;
create trigger profiles_after_delete_trigger after delete on profiles
for each row begin
  insert into changes_cache(ky, value, status) values('profile', old.uuid, 'pending') on duplicate key update updated_at = now();
end$

-- enrollments
drop trigger if exists enrollments_after_insert_trigger;
create trigger enrollments_after_insert_trigger after insert on enrollments
for each row begin
  insert into changes_cache(ky, value, status) values('enrollment', convert(new.id, char), 'pending') on duplicate key update updated_at = now();
end$

drop trigger if exists enrollments_after_update_trigger;
create trigger enrollments_after_update_trigger after update on enrollments
for each row begin
  if old.uuid != new.uuid or old.organization_id != new.organization_id or old.start != new.start or old.end != new.end then
    insert into changes_cache(ky, value, status) values('enrollment', convert(new.id, char), 'pending') on duplicate key update updated_at = now();
    if not(old.uuid <=> new.uuid) then
      insert into changes_cache(ky, value, status) values('enrollment', convert(old.id, char), 'pending') on duplicate key update updated_at = now();
    end if;
  end if;
end$

drop trigger if exists enrollments_after_delete_trigger;
create trigger enrollments_after_delete_trigger after delete on enrollments
for each row begin
  insert into changes_cache(ky, value, status) values('enrollment', convert(old.id, char), 'pending') on duplicate key update updated_at = now();
end$

delimiter ;
