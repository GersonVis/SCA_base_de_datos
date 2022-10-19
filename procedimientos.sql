delimiter //
create or replace procedure registrar_entrada(no_control_nuevo varchar(30), nombre varchar(39))
begin
     if (select count(*) from estudiante where estudiante.no_control=no_control_nuevo)=0 then
          insert into persona(nombre) values(nombre);
          set @ultimo=LAST_INSERT_ID();
          insert into estudiante(no_control, id_persona) values(no_control_nuevo, @ultimo);
          insert into accesos(id_persona) values(@ultimo);
     else 
         set @ultimo=0;
         select id_persona from estudiante where no_control=no_control_nuevo limit 1 into @ultimo;
         insert into accesos(id_persona) values(@ultimo);
     end if;
end //
delimiter ; 
call registrar_entrada("17670184", "gerson");