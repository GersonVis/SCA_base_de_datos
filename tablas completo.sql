create table personas_p(
    Id_persona bigint primary key auto_increment,
    Nombre varchar(60),
    Apellido_paterno varchar(30),
    Apellido_materno varchar(30)
);
create table carreras_p(
    Id_carrera varchar(50) primary key
);
create table estudiantes_p(
    No_control bigint primary key,
    Id_persona bigint not null unique,
    Id_carrera varchar(50) not null,
    foreign key (Id_persona) references personas_p(Id_persona) on delete cascade,
    foreign key (Id_carrera) references carreras_p(Id_carrera) 
);
create table teclas_p(
    Id_tecla varchar(1) primary key
);
create table lugares_p(
    Id_lugar varchar(30) primary key,
    Id_tecla varchar(1) not null,
    foreign key (Id_tecla) references teclas_p(Id_tecla)
);

create table Acciones_p(
    accion varchar(30) primary key,
    Id_tecla varchar(1) not null,
    foreign key (Id_tecla) references teclas_p(Id_tecla)
);

create table accesos_p(
    Id_acceso bigint primary key auto_increment,
    Id_lugar varchar(30) not null,
    Id_persona bigint not null,
    Fecha date not null default curdate(),
    Hora_entrada time not null default now(),
    Hora_salida time,
    foreign key (Id_lugar) references lugares_p(Id_lugar),
    foreign key (Id_persona) references personas_p(Id_persona) on delete cascade
);

-- creamos el registro de estudiante, el registro depende de hacer primero un registro en personas
delimiter //
create or replace procedure crear_estudiante(No_control varchar(50), Id_carrera varchar(50), Nombre varchar(50), Apellido_paterno varchar(50), Apellido_materno varchar(50))
begin
    insert into personas_p(Nombre, Apellido_paterno, Apellido_materno) values(Nombre, Apellido_paterno, Apellido_materno);
    set @Id=LAST_INSERT_ID();
    insert into estudiantes_p(No_control, Id_persona, Id_carrera) values(No_control, @Id, Id_carrera);
end //
delimiter ;


delimiter //
create or replace procedure registro(Id_lugar varchar(30), No_control bigint)
begin
    select id_persona from estudiantes_p where estudiantes_p.No_control=No_control limit 1 into @Id_persona;
    if (select count(*) from accesos_p where Hora_salida is null and Id_persona=@Id_persona and Fecha=curdate() limit 1)<>0 then
        select "debes registrar salida primero" as mensaje, "false" as solicitud;
    else
        insert into accesos_p(Id_lugar, Id_persona) values(Id_lugar, @Id_persona);
        select "registro correcto" as mensaje, "true" as solicitud;
        select * from estudiantes_p inner join personas_p using(Id_persona) where estudiantes_p.No_control=No_control;
    end if;
end //
delimiter ;


-- crea un estudiante si no existe
delimiter //
create or replace procedure registrar_entrada(Id_lugar varchar(60), No_control varchar(50), Id_carrera varchar(50), Nombre varchar(50), Apellido_paterno varchar(50), Apellido_materno varchar(50))
begin
   if (select count(*) from estudiantes_p where estudiantes_p.No_control=No_control)=0 then
        call crear_estudiante(No_control, Id_carrera, Nombre, Apellido_paterno, Apellido_materno);
        call registro(Id_lugar, No_control);
   else
        call registro(Id_lugar, No_control);
   end if;
end //
delimiter ;



-- crea un estudiante si no existe
delimiter //
create or replace procedure entrada_o_salida(Id_lugar varchar(60), No_control varchar(50), Id_carrera varchar(50), Nombre varchar(50), Apellido_paterno varchar(50), Apellido_materno varchar(50))
begin
   if (select count(*) from estudiantes_p where estudiantes_p.No_control=No_control)=0 then
        call crear_estudiante(No_control, Id_carrera, Nombre, Apellido_paterno, Apellido_materno);
        call registro(Id_lugar, No_control);
   else
        call registro(Id_lugar, No_control);
   end if;
end //
delimiter ;


-- procedure correcto
delimiter //
create or replace procedure salida(Id_persona_var bigint)
begin
        update accesos_p set Hora_salida=now() where accesos_p.Id_persona=Id_persona_var and Fecha=curdate();
end //
delimiter ;

-- registrar entrada de una persona
delimiter //
create or replace procedure entrada(Id_persona bigint, Id_lugar varchar(60))
begin
    insert into accesos_p(Id_persona, Id_lugar) values(Id_persona, Id_lugar);
end //
delimiter ;


-- procedure correcto
delimiter //
create or replace procedure buscar_id_persona(IN No_control varchar(60), OUT Id_encontrado bigint)
begin
    select Id_persona from estudiantes_p where estudiantes_p.No_control=No_control limit 1 into Id_encontrado;
end //
delimiter ;

-- entrada automatica marca salida o crea entrada
delimiter //
create or replace procedure accion_automatica(Id_persona bigint, Id_lugar varchar(40))
begin 
     if(select count(*) from accesos_p where accesos_p.Id_persona=Id_persona and Fecha=curdate() and Hora_salida is null)=0 then
        call entrada(Id_persona, Id_lugar);
        select "Entrada registrada" as mensaje, "true" as solicitud, "insert" as tipo;
     else
        call salida(Id_persona);
        select "salida registrada" as mensaje, "true" as solicitud, "update" as tipo;
     end if;
end //
delimiter ;

-- registrar o hacer una entrada o salida automatica
delimiter //
create or replace procedure registro_accion_automatica(Id_lugar varchar(60), No_control varchar(50), Id_carrera varchar(50), Nombre varchar(50), Apellido_paterno varchar(50), Apellido_materno varchar(50))
begin
    -- creamos la variable null y si no es null no creamos un nuevo usuario
    set @Id_persona=NULL;
    select Id_persona into @Id_persona from estudiantes_p where estudiantes_p.No_control=No_control;
    if @Id_persona is null then
        call crear_estudiante(No_control, Id_carrera, Nombre, Apellido_paterno, Apellido_materno);
        call encontrar_id_persona(No_control, @Id_persona);
        call accion_automatica(@Id_persona, Id_lugar);
        call ultimo_acceso(No_control);
    else
        call accion_automatica(@Id_persona, Id_lugar);
        call ultimo_acceso(No_control);
    end if;
end //
delimiter ;


-- procedimientos select
delimiter //
create or replace procedure mostrar_accesos()
begin
   select No_control, Hora_entrada, Hora_salida, Nombre, Fecha, Id_acceso from accesos_p inner join personas_p using (Id_persona) inner join estudiantes_p using(Id_persona) where Fecha=curdate();
end //
delimiter ;
delimiter //
create or replace procedure mostrar_personas()
begin
   select No_control, Nombre, Id_persona from personas_p inner join estudiantes_p using(Id_persona);
end //
delimiter ;
delimiter //
create or replace procedure mostrar_lugares()
begin
   select * from lugares_p;
end //
delimiter ;

delimiter //
create or replace procedure encontrar_id_persona(No_control varchar(30), out Id_persona bigint)
begin
   select estudiantes_p.Id_persona into Id_persona  from estudiantes_p where estudiantes_p.No_control=No_control;
end //
delimiter ;

delimiter //
create or replace procedure ultimo_acceso(No_control varchar(30))
begin
   select Id_acceso, Id_persona, Nombre, No_control, Hora_entrada, Hora_salida from accesos_p inner join estudiantes_p using(Id_persona) inner join personas_p using(Id_persona) where estudiantes_p.No_control=No_control and Fecha=curdate() order by Id_acceso desc limit 1;
end //
delimiter ;
-- fin procedimientos select

-- inserciones necesarias para el funcionamiento del sistema

insert into teclas_p values('A'),('S'),('D'),('F'),('G'), ('Q'), ('W'), ('E');
insert into Acciones_p values("Automático", "Q"), ("Entrada", "w"), ("Salida", "E");
insert into lugares_p values("Laboratorio de sistemas", 'A'),("Laboratorio de redes", 'S'), ("Laboratorio de informatica", 'D');
insert into carreras_p values("Ingeniería en sistemas computacionales"), ("Informática"), ("Ingeniería industrial");

--fin de incerciones necesarias

-- call de prueba, no son necesarios se pueden borrar, no correr

call crear_estudiante("17670174", "Ingeniería en sistemas computacionales", "Gerson", "Visoso", "Ocampo");
call registrar_entrada("Laboratorio de redes", "111111111", "Ingeniería en sistemas computacionales", "Josue díaz", "", "");

call accion_automatica(4, "Laboratorio de sistemas");

(Id_lugar varchar(60), No_control varchar(50), Id_carrera varchar(50), Nombre varchar(50), Apellido_paterno varchar(50), Apellido_materno varchar(50))
call registro_accion_automatica("Laboratorio de sistemas", "13011999", "Ingeniería en sistemas computacionales", "nuevo dato agregado", "", "");

