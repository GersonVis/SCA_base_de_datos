create table personas_p(
    Id_persona bigint primary key auto_increment,
    Nombre varchar(60),
    Apellido_paterno varchar(30),
    Apellido_materno varchar(30),
    fulltext key(Nombre,  Apellido_paterno, Apellido_materno)
);
-- ejecutar sentencia
alter table personas_p add fulltext(nombre);
create table carreras_p(
    Id_carrera varchar(50) primary key,
    Color varchar(25)
  
);
create table estudiantes_p(
    No_control varchar(10) primary  key,
    Id_persona bigint not null unique,
    Id_carrera varchar(50) not null,
    nombre_f varchar(60)
    foreign key (Id_persona) references personas_p(Id_persona) on delete cascade,
    foreign key (Id_carrera) references carreras_p(Id_carrera),
    fulltext (No_control, Id_carrera)
);

create table teclas_p(
    Id_tecla varchar(1) primary key
);
create table lugares_p(
    Id_lugar varchar(80) primary key,
    Id_tecla varchar(1) not null,
    foreign key (Id_tecla) references teclas_p(Id_tecla)
);

create table acciones_p(
    accion varchar(30) primary key,
    Id_tecla varchar(1) not null,
    foreign key (Id_tecla) references teclas_p(Id_tecla)
);

create table accesos_p(
    Id_acceso bigint primary key auto_increment,
    Id_lugar varchar(80) not null,
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
-- registra la hora de salida
delimiter //
create or replace procedure salida(Id_persona_var bigint)
begin
        update accesos_p set Hora_salida=now() where accesos_p.Id_persona=Id_persona_var and Fecha=curdate();
end //
delimiter ;

delimiter //
create or replace procedure registrar_salida(No_control varchar(30))
begin
    set @Id_persona=NULL;
    call encontrar_id_persona(No_control, @Id_persona);
    if (select count(*) from accesos_p where Id_persona=@Id_persona and Fecha=curdate() and Hora_salida is null)>0 then
        call salida(@Id_persona);
        call mensaje_api("Se registro salida correctamente", "true", "update");
        call ultimo_acceso(No_control);
    else
        call mensaje_api("Debe registrar primero una entrada", "false", "noprocedio");
    end if;
end //
delimiter ;
;


-- registrar salida si tenemos el no_control


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
   select Id_acceso, Id_persona, Nombre, No_control, Hora_entrada, Hora_salida, Id_lugar from accesos_p inner join estudiantes_p using(Id_persona) inner join personas_p using(Id_persona) where estudiantes_p.No_control=No_control and Fecha=curdate() order by Id_acceso desc limit 1;
end //
delimiter ;

delimiter //
create or replace procedure sin_salida()
begin
   select "Personas sin salida" as mensaje, "true" as solicitud, "select" as tipo;
   select * from accesos_p inner join personas_p using(Id_persona) inner join estudiantes_p using(Id_persona) where Fecha=curdate() and Hora_salida is null order by Id_acceso desc;
end //
delimiter ;
-- fin procedimientos select
-- respuestas para api
-- cambiar la forma de presentar los datos
delimiter //
create or replace procedure mensaje_api(msg varchar(100), soli varchar(10), tip varchar(40))
begin
 select msg as mensaje, soli as solicitud, tip as tipo;
end //
delimiter ;

-- fin procedimientos select

-- inserciones necesarias para el funcionamiento del sistema

insert into teclas_p values('G'),('R'),('S'),('O'),('N'), ('T'), ('I'), ('L'), ('Y'), ('C'), ('F');
insert into Acciones_p values("Automático", "G"), ("Entrada", "R"), ("Salida", "S");
insert into lugares_p values("Laboratorio de sistemas", 'O'),
("Laboratorio de Aplicaciones", 'N'),
("Laboratorio de Sistemas Embebidos", 'T'),
("Laboratorio de Redes", 'I'),
("Laboratorio de Programación", 'L'),
("Laboratorio de Electrónica", 'Y'),
("Laboratorio de Telecomunicaciones", 'C'),
("Laboratorio de Diseño", 'F');
insert into carreras_p values("Ingeniería en sistemas computacionales", "rgb(67, 153, 255)"), ("Informática", "rgb(7, 224, 125)"), ("Ingeniería industrial", "rgb(154, 247, 5)");

--fin de incerciones necesarias

-- call de prueba, no son necesarios se pueden borrar, no correr

call crear_estudiante("17670174", "Ingeniería en sistemas computacionales", "Gerson", "Visoso", "Ocampo");
call registrar_entrada("Laboratorio de redes", "111111111", "Ingeniería en sistemas computacionales", "Josue díaz", "", "");

call accion_automatica(4, "Laboratorio de sistemas");

(Id_lugar varchar(60), No_control varchar(50), Id_carrera varchar(50), Nombre varchar(50), Apellido_paterno varchar(50), Apellido_materno varchar(50))
call registro_accion_automatica("Laboratorio de sistemas", "13011999", "Ingeniería en sistemas computacionales", "nuevo dato agregado", "", "");


-- vistas
create or replace view conteo_entradas as select count(*) as conteo, id_persona from accesos_p group by id_persona;
create or replace view personas_view as select Apellido_materno, estudiantes_p.Id_persona, (select conteo from conteo_entradas where conteo_entradas.Id_persona=estudiantes_p.id_persona) as Entradas, estudiantes_p.Id_carrera, estudiantes_p.No_control, personas_p.Nombre,personas_p.Apellido_paterno, ( if((select count(*) from accesos_p WHERE accesos_p.Id_persona=estudiantes_p.Id_persona) >0,                                                                                                                                         
        if((select if(Hora_entrada is not null and Hora_salida is null, true, false) from accesos_p WHERE accesos_p.Id_persona=estudiantes_p.Id_persona and fecha=curdate() order by hora_entrada DESC limit 1), "Activo",
(select concat("Última vez: ", fecha," ", if(hora_salida=null, date_format(hora_entrada, "%r"), date_format(hora_salida, "%r"))) from accesos_p WHERE accesos_p.Id_persona=estudiantes_p.Id_persona ORDER by fecha desc, hora_entrada desc LIMIT 1)) , "Sin entradas") ) as Valor from estudiantes_p inner JOIN personas_p USING(Id_persona);