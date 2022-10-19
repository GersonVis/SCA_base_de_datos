select id_persona, No_control, nombre, fecha, Hora_entrada, Hora_salida from accesos_p inner join personas_p using(Id_persona) inner join estudiantes_p using (Id_persona);
select * from estudiantes_p;
select * from personas_p;
delete from personas_p;
delete from accesos_p;
select * from personas_p inner join estudiantes_p using(Id_persona);

select No_control, Hora_entrada, Hora_salida, Nombre, Fecha from accesos_p inner join personas_p using(id_persona) inner join estudiantes_p using(Id_persona);


| Laboratorio de sistemas    | A        |
| Laboratorio de informatica | D        |
| Laboratorio de redes       | S        |


    4 | German castro        |
|   5 | Gerson Visoso Ocampo |
|   6 | Josue díaz     