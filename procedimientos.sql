delimiter //
create or replace procedure registrar_entrada(no_control_nuevo varchar(30), nombre varchar(39))
begin
     if (select count(*) from estudiante where estudiante.no_control=no_control_nuevo)=0 then
          insert into persona(nombre) values(nombre);
          set @ultimo=LAST_INSERT_ID();
          insert into estudiante(no_control, id_persona) values(no_control_nuevo, @ultimo);
     else 
          
     end if;
end //
delimiter ; 