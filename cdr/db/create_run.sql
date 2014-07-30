insert into run (number,runtype_id) select run_number,'0' from file f on duplicate key update number=f.run_number;
insert into burst (number,run_number,run_id) select f.burst_number,f.run_number,r.id from file f left join run as r on r.number=f.run_number on duplicate key update number=f.burst_number;
