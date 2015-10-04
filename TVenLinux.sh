#!/usr/bin/env bash

###############################################
#              www.TVenLinux.com              #
#           Actualizado: 01/06/2014           #
#   Autor: Busindre (busilezas[@]gmail.com)   #
#  Programación TV: www.programacion-tdt.com  #
###############################################

# http://xmltvepg.wanwizard.eu/rytecxmltvdplus.gz --> Programacion más completa en xml (http://www.rytec.be/)
# Mirar los rtsp que no van cn mplayer para pasalro a otro reproductor cvlc "rtsp://cdns724ste1010.multistream.net:80/iberoamericatvlive/Continuidad-500" --sout=file/ts:go.mpg

############################### Configuración. (Mirar en la web www.tvenlinux.com alguna otra posibilidad no documentada aquí.).

# Filtrar por Ubicación geográfica, Temática y País (Listar separando por ",").
# Ubicación ---> ALL:Todos LA:Latinoamerica REG:Regional LOC:Local
# Temática ----> INF:Infantil NOT:Noticias MUS:Música DEP:Deportes MIX:Varios
# País --------> ES:España AR:Argentina CL:Chile CO:Colombia CU:Cuba EC:Ecuador MX:México PY:Paraguay PE:Perú VE:Venezuela
# NOTA: Si se indica solo el país, por ejemplo españa (ES), no se mostrarán canales deportivos, infantiles, musicales ni informativos de España.
# Motrar todos los Canales de España, Perú y todos los deportivos e infantiles. SHOW_CANALES=ES,INF,DEP
SHOW_CANALES=ALL

# Segundos que estará descargando el streaming de TV antes de empezar a reproducirlo, aumentar los segundos para conexiones lentas.
CACHE_STREAMING=12 

# Número de Kbytes que usará Mplayer para poder retroceder en la visualización del streaming de TV.
CACHE_MPLAYER=10000 

# Cambiando el valor a 1 no preguntará si queremos guardar lo visualizado. Útil si no te interesa guardar y se quiere evitar la pregunta.
SAVE=0 

# Usar una pila fifo en vez de guardar un fichero temporal. Valor por defecto 1 (No usa fifo.)
# Poner a 0 para usar una pila en vez de guardar un temporal
# Poner a 2 para usar la pila apoyándose en "cat" (Probar si con la opción 0 no se consigue mejora)
# NOTA: Con determinados canales el uso de la pila puede colgar TVenLinux, usar cntrl+c en consola. 
fifo=1 

# Cambiar el valor a 1 para no mostrar la ventana de "Teclas útiles de Mplayer".
MPLAYER_HELP=0 

# Cambiar el reproductor ( vlc, cvlc y ffplay ). Si prefieres que mplayer termine en vez de esperar más datos introduce: "mplayer_old".
REPRODUCTOR="mplayer"
# Si se quiere que por defecto se abra mplayer en pantalla completa, modificar la variable full con el valor "-fs", quedando full="-fs"
full="" 

ID=`date '+%s'` 
V_script="01/06/2014";

#touch /tmp/versiontv # Descomentar esta linea (Quitar la primera almohadilla) si se quiere que TVenLinux NO busque actualizaciones de forma automática.

############################### Función para obtener la Versión y mostrar un aviso.
function version {

randomversion=$[($ID % 3)]
ls /tmp/versiontv > /dev/null 2>&1
ver=$?
if [ $ver -eq 2 -a $randomversion -eq 1 ]; then # Si no existe el fichero, y el random no da 0 comprobamos, el random se utiliza para no mostrar siempre el aviso.
	echo -e " \e[00;36mBuscando si hay nuevas versiones de TVenLinux.sh\e[00m\n"
	V_actual=`curl  -r 2480-2497 -A "Mozilla 5.0" -s http://www.tvenlinux.com/ | grep -i -e "<h5>(" -e ")</h5>" | sed  -e "s/<h5>(//" -e "s/)<\/h5>//" -e "s/^[ \t]*//"`
	touch "/tmp/versiontv" ; # Para que solo muestre el aviso una vez por cada ejecución.
	
	if [ "$V_actual" != "$V_script" -a "$V_actual" != "" ]; then # Si se ha podido verificar la versión y hay actualización disponible.
	
		if [ $KDE -eq 1 ]; then
			zenity --title "Nueva versión disponible" --no-wrap --info --text="Hay una nueva versión actualizada a fecha de $V_actual.\n\nPuede descargarla de www.tvenlinux.com" ;
		else
			kdialog --msgbox  "Hay una nueva versión actualizada a fecha de $V_actual.\n\nPuede descargarla de www.tvenlinux.com" ;
		fi
	fi
	
fi

}

############################### Función para mostrar la ayuda de Mplayer (Teclas útiles).

function mplayer_keys {

ls /tmp/tvhelp > /dev/null 2>&1
tvhelp=$?

if [ $MPLAYER_HELP -eq 0 -a $KDE -eq 1 -a $tvhelp -eq 2 -a "$REPRODUCTOR" = "mplayer" ]; then

	touch /tmp/tvhelp;
	zenity --no-wrap --title "Teclas útiles" --info --text="0: Sube el volumen\n9: Baja el volumen\n( ) Balance de sonido  izda / dcha\nm: Silencio (Mute)\n\nIzquierda: Retrocede 10 segundos.\nDerecha: Avanza 10 segundos.\n\nArriba: Avanza 1 minuto.\nAbajo: Retrocede 1 minuto.\n\nAv. Pág: Retrocede 10 minutos.\nRe Pág: Avanza 10 minutos.\n\np, Espacio: Pausa / Reproducir.\n\nF: Pantalla completa.\n\nMays + t: Siempre encima.\n\nq, Esc: Cierra mplayer." ;

elif [ $MPLAYER_HELP -eq 0 -a $KDE -eq 0 -a $tvhelp -eq 2 -a "$REPRODUCTOR" = "mplayer" ]; then
	
	touch /tmp/tvhelp;
	kdialog --msgbox  "0: Sube el volumen\n9: Baja el volumen\n( ) Balance de sonido  izda / dcha\nm: Silencio (Mute)\n\nIzquierda: Retrocede 10 segundos.\nDerecha: Avanza 10 segundos.\n\nArriba: Avanza 1 minuto.\nAbajo: Retrocede 1 minuto.\n\nAv. Pág: Retrocede 10 minutos.\nRe Pág: Avanza 10 minutos.\n\np, Espacio: Pausa / Reproducir.\n\nF: Pantalla completa.\n\nMays + t: Siempre encima.\n\nq, Esc: Cierra mplayer." ;


fi
}

################################ Función para recuperar la programación.

function cmd_prog {
	echo ""$(grep -A 1 "$1" /tmp/programacion  | grep -i Programa | sed -e 's/Programa://'); 
}

function cmd_prog2 {
	echo ""$(grep -A 1 "$1" /tmp/programacion2 | grep -i Programa | sed -e 's/Programa://');
}

############################### Función para forzar configuración antigua para streamings descargados con mplayer, ya que no aceptan las opciones de reproducción por defecto.

function mplayer_conf_change {

if [ "$REPRODUCTOR" = "mplayer" ]; then 
	REPRODUCTOR="mplayer_old"
fi

}

############################### Función para cambiar el reproductor y comprueba si el mismo está o no instalado, de no estarlo, corta el streaming y sale.

function reproductor {

if  [ "$REPRODUCTOR" = "vlc" ]; then
	
	whereis -B "/usr/sbin" "/usr/local/sbin" "/sbin" "/usr/bin" "/usr/local/bin" "/bin" -b vlc | grep -i "/vlc" > /dev/null 2>&1
	repro_instalado=$?
	if [ $repro_instalado -eq 1 ]; then
		echo -e " \e[00;31mERROR: No se ha encontrado el programa $REPRODUCTOR instalado en su sistema.\e[00m\n"
		kill -1 $LASTPID > /dev/null 2>&1
		exit
	else
	
		echo -e " \e[00;36mEjecutando Vlc\e[00m\n"
		vlc /tmp/$CANAL."$ID" > /dev/null 2>&1 ;
	fi

elif  [ "$REPRODUCTOR" = "cvlc" ]; then

	whereis -B "/usr/sbin" "/usr/local/sbin" "/sbin" "/usr/bin" "/usr/local/bin" "/bin" -b cvlc | grep -i "/cvlc" > /dev/null 2>&1
	repro_instalado=$?
	if [ $repro_instalado -eq 1 ]; then
		echo -e " \e[00;31mERROR: No se ha encontrado el programa $REPRODUCTOR instalado en su sistema.\e[00m\n"
		kill -1 $LASTPID > /dev/null 2>&1
		exit
	else
	
		echo -e " \e[00;36mEjecutando Cvlc\e[00m\n"
		cvlc /tmp/$CANAL."$ID" > /dev/null 2>&1 ;

	fi

elif [ "$REPRODUCTOR" = "ffplay" ]; then

	whereis -B "/usr/sbin" "/usr/local/sbin" "/sbin" "/usr/bin" "/usr/local/bin" "/bin" -b ffplay | grep -i "/ffplay" > /dev/null 2>&1
	repro_instalado=$?
	if [ $repro_instalado -eq 1 ]; then
		echo -e " \e[00;31mERROR: No se ha encontrado el programa $REPRODUCTOR instalado en su sistema.\e[00m\n"
		kill -1 $LASTPID > /dev/null 2>&1
		exit
	else

		echo -e " \e[00;36mEjecutando ffplay\e[00m\n"
		ffplay /tmp/$CANAL."$ID" > /dev/null 2>&1 ;

	fi

elif [ "$REPRODUCTOR" = "mplayer_old" ]; then

	echo -e " \e[00;36mEjecutando Mplayer (Configuración alternativa)\e[00m\n"
	mplayer $full -vo vdpau,va,xv,gl2 -lavdopts threads=1 -really-quiet -mc 10 -autosync 30 -cache $CACHE_MPLAYER /tmp/$CANAL."$ID" > /dev/null 2>&1 ;

elif [ "$REPRODUCTOR" = "mplayer_fifo" -a $fifo -eq 0 ]; then

	echo -e " \e[00;36mEjecutando Mplayer (Configuración fifo)\e[00m\n"
 	mplayer $full -really-quiet /tmp/$CANAL."$ID" > /dev/null 2>&1 ;

elif [ "$REPRODUCTOR" = "mplayer_fifo" -a $fifo -eq 2 ]; then

	echo -e " \e[00;36mEjecutando Mplayer (Configuración fifo 2)\e[00m\n"
	cat /tmp/$CANAL."$ID" | mplayer -really-quiet - > /dev/null 2>&1 ;

elif [ "$REPRODUCTOR" = "mplayer" ]; then

	echo -e " \e[00;36mEjecutando Mplayer\e[00m\n"
	echo 'pause' > /tmp/backtv
	echo 'seek -100' >> /tmp/backtv
	mplayer $full -input file=/tmp/backtv -loop 0 -fixed-vo -ss 10000 -vo vdpau,va,xv,gl2 -lavdopts threads=1 -really-quiet -mc 10 -autosync 30 /tmp/$CANAL."$ID" > /dev/null 2>&1 ;

else
	echo -e " \e[00;31mERROR: Seleccione un reproductor válido.\e[00m\n"
	kill -1 $LASTPID > /dev/null 2>&1
	exit

fi

}
############################### Escritorio KDE.

if [ "$DESKTOP_SESSION" = "KDE" -o "$KDE_FULL_SESSION" = "true" ]; then 
	KDE=0;
else
	KDE=1;
fi

# Si no usamos KDE como escritorio pero está instalado y no queremos usar zenity, descometar esta linea.
#KDE=0

############################### Dependencias (Zenity | Kdialog, mplayer y rtmpdump).

if [ $KDE -eq 1 ]; then
	whereis -B "/usr/sbin" "/usr/local/sbin" "/sbin" "/usr/bin" "/usr/local/bin" "/bin" -b zenity | grep -i "/zenity" > /dev/null 2>&1
	zenity=$?
	if [ $zenity -eq 1 ]; then
		xterm -fa default -fs 12 -bg white -fg black  -geometry 75x2 -T "Error" -e "echo 'No se ha podido encontrar el programa "zenity" instalado en su equipo' && sleep 5" ;
		exit
	fi

else
	whereis -B "/usr/sbin" "/usr/local/sbin" "/sbin" "/usr/bin" "/usr/local/bin" "/bin" -b kdialog | grep -i "/kdialog" > /dev/null 2>&1
	kdialog=$?
	if [ $kdialog -eq 1 ]; then
		xterm -fa default -fs 12 -bg white -fg black  -geometry 75x2 -T "Error" -e "echo 'No se ha podido encontrar el programa "kdialog" instalado en su equipo' && sleep 5" ;
		exit
	fi
fi



whereis -B "/usr/sbin" "/usr/local/sbin" "/sbin" "/usr/bin" "/usr/local/bin" "/bin" -b mplayer | grep -i "/mplayer" > /dev/null 2>&1
mplayer=$?
if [ $mplayer -eq 1 -a $KDE -eq 1 -a "$REPRODUCTOR" = "mplayer" ]; then
	zenity --no-wrap --error --text='No se ha podido encontrar el programa "mplayer" instalado en su equipo' ;
	exit
elif [ $mplayer -eq 1 -a $KDE -eq 0 -a "$REPRODUCTOR" = "mplayer" ]; then
	kdialog --title 'Dependencia no encontrada' --error 'No se ha podido encontrar el programa "mplayer" instalado en su equipo' ;
	exit
fi



whereis -B "/usr/sbin" "/usr/local/sbin" "/sbin" "/usr/bin" "/usr/local/bin" "/bin" -b rtmpdump | grep -i "/rtmpdump" > /dev/null 2>&1
rtmpdump=$?
if [ $rtmpdump -eq 1  -a $KDE -eq 1 ]; then
	zenity --no-wrap --error --text='No se ha podido encontrar el programa "rtmpdump" instalado en su equipo' ;
	exit
elif [ $rtmpdump -eq 1  -a $KDE -eq 0 ]; then
	kdialog --title 'Dependencia no encontrada' --error 'No se ha podido encontrar el programa "rtmpdump" instalado en su equipo' ;
	exit
fi

################################ Curl como dependencia / Programación de cada canal. 

whereis -B "/usr/sbin" "/usr/local/sbin" "/sbin" "/usr/bin" "/usr/local/bin" "/bin" -b curl | grep -i "/curl" > /dev/null 2>&1
curl=$?
if [ $curl -eq 1 -a $KDE -eq 1 ]; then
	zenity --no-wrap --warning --timeout=2 --text='No se ha podido encontrar el programa "curl" instalado en su equipo, no podrá visualizar el nombre de los programas en activo' ;
	curl=1;

elif [ $curl -eq 1 -a $KDE -eq 0 ]; then

	kdialog --warningcontinuecancel 'No se ha podido encontrar el programa "curl" instalado en su equipo, no podrá visualizar el nombre de los programas en activo' ;
	curl=1;

else
	version # Comprobamos la versión del script llamando a la función para avisar al usuario.

	curl -s http://www.programacion-tdt.com/ahora.php | iconv -t utf-8 -f iso-8859-1 | grep -A 1 -i "<td" |  sed -e 's/<td width="250" valign="top">/Canal: /' -e 's/<\/td>/ /' -e 's/<\/tr>/ /' -e 's/<td width="70%"><span class="ind">/Programa: /' -e 's/<\/span> comenzó/ [/' -e 's/minutos/minutos ]/'  -e 's/segundos/segundos ]/' -e 's/     //' > /tmp/programacion
	
	curl -s http://www.formulatv.com/programacion/ | iconv -t utf-8 -f iso-8859-1 | grep -i -A 1 "prga-i" | sed -e 's/.*prga-i"><a title="/Canal: /' -e 's/" href.*/ /' -e 's/.*prga-p">/Programa: /' -e 's/\t*<.*>//' > /tmp/programacion2

	curl=0;

fi

grep "TVE1" /tmp/programacion  > /dev/null 2>&1 && grep "La 1" /tmp/programacion2 > /dev/null 2>&1
programacion=$?
if [ $programacion -eq 1 -a $curl -eq 0 -a $KDE -eq 1 ]; then # Si no se encontraron los canales en el fichero pero sí está instalado curl (Fallo al conectar).
	zenity --no-wrap --warning --timeout=2 --text='No se ha podido descargar la programación de cada canal' ;
	curl=1;

elif [ $programacion -eq 1 -a $curl -eq 0 -a $KDE -eq 0 ]; then
	kdialog --warningcontinuecancel 'No se ha podido descargar la programación de cada canal' ;
	curl=1;

fi

################################ Carga de valores de Canales, temáticas y Programación

AHORA=`date`;
i=0;
# Nombre					Temática				Programación
if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "ES" ]]; then
	canales[i]="rtve1";		tematica[i]=" Público generalista";		prog[i++]=`cmd_prog "TVE1 $"`;
	canales[i]="rtve2";		tematica[i]=" Público cultural";		prog[i++]=`cmd_prog "La 2 $"`;
	canales[i]="Antena_3";		tematica[i]=" Generalista";			prog[i++]=`cmd_prog "Antena 3 $"`;
	canales[i]="Cuatro";		tematica[i]=" Generalista";			prog[i++]=`cmd_prog  "Cuatro $"`;
	canales[i]="Tele5";		tematica[i]=" Generalista/Amarillista";		prog[i++]=`cmd_prog "Telecinco $"`;
	canales[i]="La_Sexta";		tematica[i]=" Generalista";			prog[i++]=`cmd_prog "La Sexta $"`;
	canales[i]="Xplora";		tematica[i]=" Documentales/Masculino";		prog[i++]=`cmd_prog "xplora $"`;
	canales[i]="Energy";		tematica[i]=" Documentales/Masculino";		prog[i++]=`cmd_prog "Energy $"`;
	canales[i]="Nitro";		tematica[i]=" Series/Cine/Masculino";		prog[i++]=`cmd_prog "Nitro $"`;
	canales[i]="Neox";		tematica[i]=" Series/Jóvenes";			prog[i++]=`cmd_prog "A3 Neox $"`;
	canales[i]="Divinity";		tematica[i]=" Series/Docu/Femenino";		prog[i++]=`cmd_prog "Divinity $"`;
	canales[i]="SyFy";		tematica[i]=" Ciencia ficción";			prog[i++]=`cmd_prog2 "SyFy España $"`;
	canales[i]="Xtrm";		tematica[i]=" Cine/Acción";			prog[i++]=`cmd_prog2 "XTREM $"`;
	canales[i]="TNT";		tematica[i]=" Series/Cine";			prog[i++]=`cmd_prog2 "TNT España $"`;
	canales[i]="FDF";		tematica[i]=" Series Tele5";			prog[i++]=`cmd_prog "FDF $"`;
	canales[i]="Cosmo";		tematica[i]=" Canal femenino";			prog[i++]=`cmd_prog2 "Cosmopolitan $"`;
	canales[i]="13TV";		tematica[i]=" Cine/Religión";			prog[i++]=`cmd_prog "13 TV $"`;
	canales[i]="Paramount";		tematica[i]=" Cine";				prog[i++]=`cmd_prog2 "Paramount Channel $"`;
	canales[i]="Esne_TV";		tematica[i]=" Religión Arizona (ESP)";		prog[i++]=" - ";
	canales[i]="La_Sexta_3";	tematica[i]=" Cine";				prog[i++]=`cmd_prog2 "laSexta3 $"`;
	canales[i]="BusinessTV";	tematica[i]=" Política/Economía";		prog[i++]=" - ";
	canales[i]="Intereconomia";	tematica[i]=" Política/Religión";		prog[i++]=`cmd_prog "Intereconomia TV $"`;
	canales[i]="Discovery_Channel"; tematica[i]=" Documentales";			prog[i++]=`cmd_prog2 "Discovery Channel $"`;
	canales[i]="IberoamericaTV";	tematica[i]=" Mundo latino";			prog[i++]=" - ";
	canales[i]="Calle13";	        tematica[i]=" Series/Cine";		        prog[i++]=`cmd_prog2 "Calle 13 $"`;
	canales[i]="Historia";	        tematica[i]=" Documentales Historia";		prog[i++]=`cmd_prog2 "Canal de Historia $"`;
	canales[i]="Eurosport";	        tematica[i]=" Deporte";				prog[i++]=`cmd_prog2 "Eurosport $"`;
	canales[i]="Hollywood";	        tematica[i]=" Cine";		        	prog[i++]=`cmd_prog2 "Canal Hollywood $"`;
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "ES" ]] || [[ "$SHOW_CANALES" =~ "REG" ]]; then
	canales[i]="Andalucia";		tematica[i]=" Regional Andalucía";		prog[i++]=`cmd_prog "Canal Sur $"`;
	canales[i]="Aragon_TV";		tematica[i]=" Regional Aragón";			prog[i++]=`cmd_prog "Aragon Television $"`;
	canales[i]="TPA_a7";		tematica[i]=" Regional Asturias";		prog[i++]=`cmd_prog "TPA a7 $"`;
	canales[i]="StvRioja";		tematica[i]=" Regional La Rioja";		prog[i++]=" - ";
	canales[i]="Cyl7";		tematica[i]=" Regional Castilla León";		prog[i++]=`cmd_prog "cyl7 $"`;
	canales[i]="Etb_SAT";		tematica[i]=" Regional Vasco";			prog[i++]=" - ";
	canales[i]="TV3";		tematica[i]=" Regional Cataluña";		prog[i++]=`cmd_prog "TV3 $"`;
	canales[i]="TV3CAT";		tematica[i]=" Regional Cataluña";		prog[i++]=`cmd_prog2 "TV3 $"`;
	canales[i]="Canal9_24";		tematica[i]=" Regional Valencia";		prog[i++]=`cmd_prog "Noudos $"`;
	canales[i]="Canarias";		tematica[i]=" Regional Canarias";		prog[i++]=`cmd_prog2 "TV Canaria $"`;
	canales[i]="Canarias_NET";	tematica[i]=" Regional Canarias";		prog[i++]=" - ";
	canales[i]="Galicia_TV_AM";	tematica[i]=" Regional Galicia";		prog[i++]=`cmd_prog "Galicia TV America $"`;
	canales[i]="Galicia_TV_EU";	tematica[i]=" Regional Galicia";		prog[i++]=`cmd_prog2 "TVG $"`;
	canales[i]="Telemadrid_Otra";	tematica[i]=" Regional Madrid";			prog[i++]=`cmd_prog "La Otra $"`;
	canales[i]="Telemadrid_SAT";	tematica[i]=" Regional Madrid";			prog[i++]=" - ";
	canales[i]="Canal_Extremadura";	tematica[i]=" Regional Extremadura";		prog[i++]=`cmd_prog2 "Canal Extremadura $"`;
	
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "ES" ]] || [[ "$SHOW_CANALES" =~ "LOC" ]]; then
	canales[i]="Abteve";		tematica[i]=" Local Albacete";			prog[i++]=" - ";
	canales[i]="TeleB";		tematica[i]=" Local Badalona";			prog[i++]=" - ";
	canales[i]="IB3";		tematica[i]=" Local Baleares";			prog[i++]=`cmd_prog "IB3 $"`;
	canales[i]="TeleBilbao";	tematica[i]=" Local Bilbao";			prog[i++]=" - ";
	canales[i]="UnaCadiz";		tematica[i]=" Local Cádiz";			prog[i++]=" - ";
	canales[i]="TVCS";		tematica[i]=" Local Castellón";			prog[i++]=" - ";
	canales[i]="VoTV";		tematica[i]=" Local Cataluña";			prog[i++]=" - ";
	canales[i]="Canal_8";		tematica[i]=" Local Cataluña";			prog[i++]=`cmd_prog "8tv $"`;
	canales[i]="Canal_33";		tematica[i]=" Cultural Cataluña";		prog[i++]=" - ";
	canales[i]="ImasTV";		tematica[i]=" Local Ciudad Real";		prog[i++]=" - ";
	canales[i]="RtvCE";		tematica[i]=" Local Ceuta";			prog[i++]=" - ";
	canales[i]="TV_Girona";		tematica[i]=" Local Girona";			prog[i++]=" - ";
	canales[i]="Huelva_TV";		tematica[i]=" Local Huelva";			prog[i++]=" - ";
	canales[i]="Huesca_TV";		tematica[i]=" Local Huesca";			prog[i++]=" - ";
	canales[i]="Lancelot";		tematica[i]=" Local Lanzarote";			prog[i++]=" - ";
	canales[i]="LevanteTV";		tematica[i]=" Local Levante";			prog[i++]=" - ";
	canales[i]="Onda_Azul";		tematica[i]=" Local Málaga";			prog[i++]=" - ";
	canales[i]="PTV_Malaga";	tematica[i]=" Local Málaga";			prog[i++]=" - ";
	canales[i]="M95TV";		tematica[i]=" Local Marbella";			prog[i++]=" - ";
	canales[i]="TVMelilla";		tematica[i]=" Local Melilla";			prog[i++]=" - ";
	canales[i]="Teleminho";		tematica[i]=" Local Ourense";			prog[i++]=" - ";
	canales[i]="Ribera_TV";		tematica[i]=" Local La Ribera";			prog[i++]=" - ";
	canales[i]="TVRioja";		tematica[i]=" Local Rioja";			prog[i++]=" - ";
	canales[i]="Telebahia";		tematica[i]=" Local Santander";			prog[i++]=" - ";
	canales[i]="SolidariaTV";	tematica[i]=" Religión Vitoria";		prog[i++]=" - ";
	canales[i]="ZaragozaTV";	tematica[i]=" Local Zaragoza";			prog[i++]=" - ";
	canales[i]="Eldia_TV";		tematica[i]=" Local Tenerife";			prog[i++]=" - ";
	canales[i]="TeleToledo";	tematica[i]=" Local Toledo";			prog[i++]=" - ";
	canales[i]="Canal_Vasco";	tematica[i]=" Local Vasco";			prog[i++]=" - ";
	canales[i]="LUX_Mallorca";	tematica[i]=" Local Mallorca";			prog[i++]=" - ";
	canales[i]="CostadelSol_TV";	tematica[i]=" Local Costa del Sol";		prog[i++]=" - ";
	canales[i]="InformacionTV";	tematica[i]=" Local Alicante";			prog[i++]=" - ";
	canales[i]="Cetelmon_TV";	tematica[i]=" Religión Alicante";		prog[i++]=" - ";
	canales[i]="BarcelonaTV";	tematica[i]=" Local ciudad BCN";		prog[i++]=`cmd_prog "Barcelona TV $"`;
	canales[i]="Huelva_CNH";	tematica[i]=" Local Huelva";			prog[i++]=" - ";
	canales[i]="UnaCordoba";	tematica[i]=" Local Córdoba";			prog[i++]=" - ";
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "INF" ]]; then
	canales[i]="Super3";		tematica[i]=" Infantil Cataluña";		prog[i++]=`cmd_prog "Canal Super3 $"`;
	canales[i]="Kanal_D";		tematica[i]=" Infantil/Educativo (SR)";		prog[i++]=" - ";
	canales[i]="Sat7_Kids";		tematica[i]=" Infantil/Educativo (EN)";		prog[i++]=" - ";
	canales[i]="Minika_GO";		tematica[i]=" Infantil/Educativo (TUR)";	prog[i++]=" - ";
	canales[i]="Yumurcak";		tematica[i]=" Infantil/Educativo (TUR)";	prog[i++]=" - ";
	canales[i]="SmileofaChildTV";	tematica[i]=" Infantil/Educativo (EN)";		prog[i++]=" - ";
	canales[i]="Barbaraki_TV";	tematica[i]=" Infantil/Educativo (RUS)";	prog[i++]=" - ";
	canales[i]="Gang_Cartoon_Channel";tematica[i]=" Infantil/Anime (THA)";		prog[i++]=" - ";
	canales[i]="Minika_Cocuk";	tematica[i]=" Infantil/Educativo (TUR)";	prog[i++]=" - ";	
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "NOT" ]]; then
	canales[i]="rtve24";		tematica[i]=" Noticias 24/7 (ESP)";		prog[i++]=`cmd_prog "Canal 24h $"`;
	canales[i]="Hispan_TV";		tematica[i]=" Noticias 24/7 Irán (ESP)";	prog[i++]=" - ";
	canales[i]="France24";		tematica[i]=" Noticias 24/7 (ENG)";		prog[i++]=" - ";
	canales[i]="PressTV";		tematica[i]=" Noticias 24/7 (ENG)";		prog[i++]=" - ";
	canales[i]="TV3_24";		tematica[i]=" Noticias 24/7 (CAT)";		prog[i++]=`cmd_prog "3 24 $"`;
	canales[i]="Canal5";		tematica[i]=" Noticias 24/7";			prog[i++]=" - ";
	canales[i]="Canal26";		tematica[i]=" Noticias 24/7";			prog[i++]=" - ";
	canales[i]="TN";		tematica[i]=" Noticias 24/7";			prog[i++]=" - ";
	canales[i]="TN_2";		tematica[i]=" Noticias 24/7";     		prog[i++]=" - ";
	canales[i]="Cable_Noticias";	tematica[i]=" Noticias 24/7";			prog[i++]=" - ";
	canales[i]="Aljazeera_Eng";	tematica[i]=" Noticias 24/7 (ENG)";		prog[i++]=" - ";
	canales[i]="EuroNews_ES";	tematica[i]=" Noticias 24/7 (ESP)";		prog[i++]=" - ";
	canales[i]="Russian_Today";	tematica[i]=" Noticias 24/7 (ESP)";		prog[i++]=" - ";
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "MUS" ]]; then
	canales[i]="KissTV";		tematica[i]=" Música 24/7";			prog[i++]=" - ";
	canales[i]="LobasTV";		tematica[i]=" Música 24/7 Divas";		prog[i++]=" - ";
	canales[i]="PartyTV";		tematica[i]=" Música 24/7";			prog[i++]=" - ";
	canales[i]="TV105";		tematica[i]=" Música 24/7";			prog[i++]=" - ";
	canales[i]="Unlove";		tematica[i]=" Música 24/7";			prog[i++]=" - ";
	canales[i]="QMusica";		tematica[i]=" Música 24/7 (ESP)";		prog[i++]=" - ";
	canales[i]="MusicBox";		tematica[i]=" Música 24/7 (RUS)";		prog[i++]=" - ";
	canales[i]="GoticaTV";		tematica[i]=" Música 24/7 Gótica";		prog[i++]=" - ";
	canales[i]="StreetclipTV";	tematica[i]=" Música 24/7 Rock Metal";		prog[i++]=" - ";
	canales[i]="Eska";		tematica[i]=" Música 24/7 (POL/Global)";	prog[i++]=" - ";
	canales[i]="Humorbox";		tematica[i]=" Música 24/7 (RUS)";		prog[i++]=" - ";
	canales[i]="Funtv";		tematica[i]=" Música 24/7 (RUS/Global)";	prog[i++]=" - ";
	canales[i]="RblTV";		tematica[i]=" Música 24/7 (RUS/Global)";	prog[i++]=" - ";
	canales[i]="RMC_TV";		tematica[i]=" Música 24/7 (FR/ITA)";		prog[i++]=" - ";
	canales[i]="ShansonTV";		tematica[i]=" Música 24/7 (RUS/Global)";	prog[i++]=" - ";
	canales[i]="LaBelleTV";		tematica[i]=" Música 24/7 (FR)";		prog[i++]=" - ";
	canales[i]="DeluxeMusic";	tematica[i]=" Música 24/7";			prog[i++]=" - ";
	canales[i]="MTV";	        tematica[i]=" Música/Programas";		prog[i++]=`cmd_prog2 "MTV España $"`;
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi
	
if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "DEP" ]]; then
	canales[i]="FacetasDeportivas";	tematica[i]=" Deportes 24/7";			prog[i++]=" - ";
	canales[i]="Al_Iraqiya_Sports";	tematica[i]=" Deportes 24/7 (IRQ)";		prog[i++]=" - ";
	canales[i]="Esport3";		tematica[i]=" Deportes Cataluña (CAT)";		prog[i++]=`cmd_prog "Esport3 $"`;
	canales[i]="RedBull";		tematica[i]=" Deportes/Música (ENG)";		prog[i++]=" - ";
	canales[i]="TileSport";		tematica[i]=" Deportes 24/7 (GRE)";		prog[i++]=" - ";
	canales[i]="SportItalia";	tematica[i]=" Deportes 24/7 (ITA)";		prog[i++]=" - ";
	canales[i]="tdp";		tematica[i]=" Deportes";			prog[i++]=`cmd_prog "Teledeporte $"`;
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi


if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "MIX" ]]; then
	canales[i]="NASA";		tematica[i]=" Didáctico ciencia (ENG)";		prog[i++]=" - ";
	canales[i]="SkyPoker";		tematica[i]=" Poker 24/7 (ENG)";		prog[i++]=" - ";
	canales[i]="VaughanTV";		tematica[i]=" Aprender Inglés (ENG/ESP)";	prog[i++]="";
	canales[i]="Ondamex";		tematica[i]=" Tarot/Contactos";			prog[i++]=" - ";
	canales[i]="Astrocanalshop";	tematica[i]=" Teletienda";			prog[i++]=" - ";
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

	
if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "LA" ]] || [[ "$SHOW_CANALES" =~ "AR" ]]; then

	canales[i]="Canal3";		tematica[i]=" Generalista Argentina";		prog[i++]=" - ";
	canales[i]="Canal7";		tematica[i]=" Generalista Argentina";		prog[i++]=" - ";
	canales[i]="Canal_9";		tematica[i]=" Generalista Argentina";		prog[i++]=" - ";
	canales[i]="N9";		tematica[i]=" Generalista/Noticias";		prog[i++]=" - ";
	canales[i]="Canal13";		tematica[i]=" Generalista Argentina";		prog[i++]=" - ";
	canales[i]="LapachoTV";		tematica[i]=" Generalista Argentina";		prog[i++]=" - ";
	canales[i]="Zona31";		tematica[i]=" Generalista Argentina";		prog[i++]=" - ";
	canales[i]="El_trece";		tematica[i]=" Generalista Argentina";		prog[i++]=" - ";
	canales[i]="Canal21";		tematica[i]=" Religión Buenos Aires";		prog[i++]=" - ";
	canales[i]="El_Rural";		tematica[i]=" Mundo rural";			prog[i++]=" - ";
	canales[i]="PakaPaka";		tematica[i]=" Infantil/Educativo";		prog[i++]=" - ";
	canales[i]="Canal10";		tematica[i]=" Local Córdoba";			prog[i++]=" - ";
	canales[i]="CBA24";		tematica[i]=" Local Córdoba";			prog[i++]=" - ";
	canales[i]="ArgentinisimaTV";	tematica[i]=" Generalista Argentina";		prog[i++]=" - ";
	canales[i]="Canal_Provincial";	tematica[i]=" Generalista Argentina";		prog[i++]=" - ";
	canales[i]="Construir_TV";	tematica[i]=" Tema construcción";		prog[i++]=" - ";
	canales[i]="Canal10_Tucuman";	tematica[i]=" Local Tucumán";			prog[i++]=" - ";
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "LA" ]] || [[ "$SHOW_CANALES" =~ "CL" ]]; then
	canales[i]="AricaTV";		tematica[i]=" Generalista Chile";		prog[i++]=" - ";
	canales[i]="Canal2";		tematica[i]=" Generalista Chile";		prog[i++]=" - ";
	canales[i]="Canal9";		tematica[i]=" Generalista Chile";		prog[i++]=" - ";
	canales[i]="Enlace";		tematica[i]=" Generalista Chile";		prog[i++]=" - ";
	canales[i]="Canal33";		tematica[i]=" Generalista Chile";		prog[i++]=" - ";
	canales[i]="TVinet";		tematica[i]=" Generalista Chile";		prog[i++]=" - ";
	canales[i]="Itv";		tematica[i]=" Generalista Chile";		prog[i++]=" - ";
	canales[i]="RedTV";		tematica[i]=" Generalista Chile";		prog[i++]=" - ";
	canales[i]="MegaTV";		tematica[i]=" Generalista Chile";		prog[i++]=" - ";
	canales[i]="Horas24";		tematica[i]=" Generalista Chile";		prog[i++]=" - ";
	canales[i]="RTC";		tematica[i]=" Generalista Chile";		prog[i++]=" - ";
	canales[i]="TVlota";		tematica[i]=" Generalista Chile";		prog[i++]=" - ";
	canales[i]="MetroTV";		tematica[i]=" TV Metro de Santiago";		prog[i++]=" - ";
	canales[i]="TVu";		tematica[i]=" Universidad Concepción";		prog[i++]=" - ";
	canales[i]="SenadoTV";		tematica[i]=" TV Senado Chile";			prog[i++]=" - ";
	canales[i]="UNIACCTV";		tematica[i]=" Universidad ACC";			prog[i++]=" - ";
	canales[i]="UATV";		tematica[i]=" Universidad Autónoma";		prog[i++]=" - ";
	canales[i]="UMAGTV";		tematica[i]=" Universidad Magallanes";		prog[i++]=" - ";
	canales[i]="TVnuevotiempo";	tematica[i]=" Religión Chile";			prog[i++]=" - ";
	canales[i]="Digital_Channel";	tematica[i]=" Generalista Chile";		prog[i++]=" - ";

	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "LA" ]] || [[ "$SHOW_CANALES" =~ "CO" ]]; then
	canales[i]="Tu_Kanal";		tematica[i]=" Generalista Colombia";		prog[i++]=" - ";
	canales[i]="PyC";		tematica[i]=" Generalista Colombia";		prog[i++]=" - ";
	canales[i]="RTVC";		tematica[i]=" Generalista Colombia";		prog[i++]=" - ";
	canales[i]="RTVC2";		tematica[i]=" Generalista Colombia";		prog[i++]=" - ";
	canales[i]="CMB";		tematica[i]=" Religión Colombia";		prog[i++]=" - ";
	canales[i]="CristoVision";	tematica[i]=" Religión Colombia";		prog[i++]=" - ";
	canales[i]="TeleVida";		tematica[i]=" Religión Colombia";		prog[i++]=" - ";
	canales[i]="TeleCaribe";	tematica[i]=" Generalista Colombia";		prog[i++]=" - ";
	canales[i]="TelePacifico";	tematica[i]=" Generalista Colombia";		prog[i++]=" - ";
	canales[i]="Canal_Tiempo";	tematica[i]=" Meteorología/Noticias";		prog[i++]=" - ";
	canales[i]="Canal_Capital";	tematica[i]=" Generalista Colombia";		prog[i++]=" - ";
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "LA" ]] || [[ "$SHOW_CANALES" =~ "CU" ]]; then
	canales[i]="CubaVision";	tematica[i]=" Generalista Cuba";		prog[i++]=" - ";
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "LA" ]] || [[ "$SHOW_CANALES" =~ "EC" ]]; then
	canales[i]="RTS";		tematica[i]=" Generalista Ecuador";		prog[i++]=" - ";
	canales[i]="Canal1";		tematica[i]=" Generalista Ecuador";		prog[i++]=" - ";
	canales[i]="Ecuadortv";		tematica[i]=" Generalista Ecuador";		prog[i++]=" - ";
	canales[i]="Oromar";		tematica[i]=" Generalista Ecuador";		prog[i++]=" - ";
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "LA" ]] || [[ "$SHOW_CANALES" =~ "MX" ]]; then
	canales[i]="TelevisaHD";	tematica[i]=" Generalista Mexico";		prog[i++]=" - ";
	canales[i]="OnceTV";		tematica[i]=" Generalista Mexico";		prog[i++]=" - ";
	canales[i]="Canal7_KHSLV";	tematica[i]=" Generalista Mexico";		prog[i++]=" - ";
	canales[i]="TVazteca";		tematica[i]=" Generalista Mexico";		prog[i++]=" - ";
	canales[i]="TVazteca_news";	tematica[i]=" Generalista/Noticias";		prog[i++]=" - ";
	canales[i]="Milenio";		tematica[i]=" Noticias/Política";		prog[i++]=" - ";
	canales[i]="Canal66";		tematica[i]=" Noticias/Reportajes";		prog[i++]=" - ";
	canales[i]="Canal44";		tematica[i]=" Noticias/Reportajes";		prog[i++]=" - ";
	canales[i]="Congreso";		tematica[i]=" Canal del congreso";		prog[i++]=" - ";
	canales[i]="Canal_Justicia";	tematica[i]=" Ministerio Justicia";		prog[i++]=" - ";
	canales[i]="Cortes_Diputados";	tematica[i]=" Cortes Diputados";		prog[i++]=" - ";
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "LA" ]] || [[ "$SHOW_CANALES" =~ "PY" ]]; then
	canales[i]="RPC";		tematica[i]=" Generalista Paraguay";		prog[i++]=" - ";
	canales[i]="Paravision";	tematica[i]=" Generalista Paraguay";		prog[i++]=" - ";
	canales[i]="TeleFuturo";	tematica[i]=" Generalista Paraguay";		prog[i++]=" - ";
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "LA" ]] || [[ "$SHOW_CANALES" =~ "PE" ]]; then
	canales[i]="Global_TV";		tematica[i]=" Generalista Perú";		prog[i++]=" - ";
	canales[i]="ATV_Sur";		tematica[i]=" Generalista Perú";		prog[i++]=" - ";
	canales[i]="Panamericana";	tematica[i]=" Generalista Perú";		prog[i++]=" - ";
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi

if [ "$SHOW_CANALES" = "ALL" ] || [[ "$SHOW_CANALES" =~ "LA" ]] || [[ "$SHOW_CANALES" =~ "VE" ]]; then
	canales[i]="TeleSur";		tematica[i]=" Generalista Venezuela";		prog[i++]=" - ";
	canales[i]="AtelTV";		tematica[i]=" Generalista Venezuela";		prog[i++]=" - ";
	canales[i]="DatTV";		tematica[i]=" Generalista Venezuela";		prog[i++]=" - ";
	canales[i]="VTV";		tematica[i]=" Generalista Venezuela";		prog[i++]=" - ";
	canales[i]="IslaTV";		tematica[i]=" Generalista Venezuela";		prog[i++]=" - ";
	canales[i]="PromarTV";		tematica[i]=" Generalista Venezuela";		prog[i++]=" - ";
	canales[i]="TVes";		tematica[i]=" Generalista Venezuela";		prog[i++]=" - ";
	canales[i]="TicTV";		tematica[i]=" Generalista Venezuela";		prog[i++]=" - ";
	canales[i]="TrpTV";		tematica[i]=" Generalista Venezuela";		prog[i++]=" - ";
	canales[i]="TVO";		tematica[i]=" Generalista Venezuela";		prog[i++]=" - ";
	canales[i]="TamTV";		tematica[i]=" Noticias / Cultura Mérida";	prog[i++]=" - ";
	canales[i]="";			tematica[i]="";					prog[i++]="";
fi


############################## Canales en Pantalla.

if [ $curl -eq 0  -a $KDE -eq 1 ]; then # Muestra la programación (Zenity)

  j=0;
  for (( i=0; i<$(( ${#canales[*]} )); i++ ))
  do
   listado[j]="${canales[$i]}";
   listado[j+1]="${tematica[$i]}";
   listado[j+2]="${prog[$i]}";
   j=$j+3;
  done

	CANAL=`zenity --window-icon="/usr/share/icons/hicolor/48x48/devices/totem-tv.png" --list --title="TVenLinux ($V_script)" --text="Seleccione un canal" --height=450 --width=750 --column="Canales" --column="Temática" --column="Emisión $AHORA " "${listado[@]}"`

elif [ $curl -eq 0  -a $KDE -eq 0 ]; then # Muestra la programación (Kde)

  j=0;
  for (( i=0; i<$(( ${#canales[*]} )); i++ ))
  do
    listado[j]="${canales[$i]}";
    listado[j+1]="${canales[$i]}                ${tematica[$i]}               ${prog[$i]}";
    j=$j+2;
  done

  CANAL=`kdialog  --title "TVenLinux ($V_script)" --geometry 650x600 --menu "Seleccione un canal  [ $AHORA ]" "${listado[@]}"`

elif [ $curl -eq 1  -a $KDE -eq 1 ]; then # NO Muestra la programación, solo temática (Zenity)

  j=0;
  for (( i=0; i<$(( ${#canales[*]} )); i++ ))
  do
    listado[j]="${canales[$i]}";
    listado[j+1]="${tematica[$i]}";
    j=$j+2;
  done
	# Si no se pudo conectar a la programación mostramos este dialogo sin la programación.
	CANAL=`zenity --window-icon="/usr/share/icons/hicolor/48x48/devices/totem-tv.png" --list --title="TVenLinux ($V_script)" --text="Seleccione un canal" --height=450 --width=370 --column="Canales" --column="Temática" "${listado[@]}"`


elif [ $curl -eq 1  -a $KDE -eq 0 ]; then # NO Muestra la programación, solo temática (Kde)

  j=0;
  for (( i=0; i<$(( ${#canales[*]} )); i++ ))
  do
    listado[j]="${canales[$i]}";
    listado[j+1]="${canales[$i]}		${tematica[$i]}";
    j=$j+2;
  done
	CANAL=`kdialog  --title "TVenLinux ($V_script)" --geometry 440x600 --menu "Seleccione un Canal" "${listado[@]}"`


fi

############################## Opción FIFO

if [ $fifo -eq 0 -o $fifo -eq 2 ]; then # Se crea la fifo y forzamos usar mplayer sin parámetros con la pila.
	mkfifo /tmp/$CANAL."$ID"
	SAVE=0
	
	if [ "$REPRODUCTOR" = "mplayer" -o  "$REPRODUCTOR" = "vlc" ]; then # Fuerza el uso de Mplayer si usa vlc y da libertad a usar ffplay
		REPRODUCTOR="mplayer_fifo"
	fi
fi

############################## Descarga el streaming del canal seleccionado.

case $CANAL in

	rtve1) rtmpdump -r "rtmp://rtvefs.fplive.net:1935/rtve-live-live?ovpfv=2.1.2/RTVE_LA1_LV3_WEB_NOG" -W "http://www.irtve.es/swf/4.2.15/RTVEPlayerVideo.swf" -q -v > /tmp/$CANAL."$ID" & ;;

	rtve2) rtmpdump -r "rtmp://rtvefs.fplive.net:1935/rtve-live-live?ovpfv=2.1.2/RTVE_LA2_LV3_WEB_NOG" -W "http://www.irtve.es/swf/4.2.15/RTVEPlayerVideo.swf" -q -v > /tmp/$CANAL."$ID" & ;;

	rtve24) rtmpdump -m 200 -r "rtmp://rtvefs.fplive.net:1935/rtve-live-live?ovpfv=2.1.2" -y "RTVE_24H_LV3_WEB_NOG" -W "http://www.irtve.es/swf/4.2.15/RTVEPlayerVideo.swf" -p "http://www.rtve.es"  -C S:OK -q -v > /tmp/$CANAL."$ID" &  ;;

	tdp) rtmpdump -m 200 -r "rtmp://rtvegeofs.fplive.net:1935/rtvegeo-live-live/RTVE_TDP_LV3_WEB_GEO" -y "RTVE_TDP_LV3_WEB_GEO" -W "http://www.irtve.es/swf/4.2.15/RTVEPlayerVideo.swf" -p "http://www.rtve.es/deportes/directo/teledeporte" -q -v > /tmp/$CANAL."$ID" & ;;

	#tdp) rtmpdump -m 200 -r "rtmp://rtvegeofs.fplive.net:1935/rtvegeo-live-live" -y "RTVE_TDP_LV3_WEB_GEO?aksessionid=1364156661735_65518" -W "http://www.rtve.es/swf/4.1.20/RTVEPlayerVideo.swf" -p "http://www.rtve.es/deportes/directo/teledeporte" -q -v > /tmp/$CANAL."$ID" & ;;

	#tdp) rtmpdump -m 200 -r "rtmp://rtvegeofs.fplive.net:1935/rtvegeo-live-live" -y "RTVE_TDP_LV3_WEB_GEO?aksessionid=1364156661735_65518" -W "http://www.rtve.es/swf/4.1.20/RTVEPlayerVideo.swf" -p "http://www.rtve.es/deportes/directo/teledeporte" -C Z: -q -v > /tmp/$CANAL."$ID" & ;;


	Antena_3) rtmpdump -m 200 -r "rtmp://antena3fms35livefs.fplive.net:1935/antena3fms35live-live" -y "stream-antena3_1" -W "http://www.antena3.com/static/swf/A3Player.swf?nocache=200" -p "http://www.antena3.com/directo/" -q -v > /tmp/$CANAL."$ID" & ;;

	La_Sexta) rtmpdump -m 200 -r "rtmp://antena3fms35livefs.fplive.net:1935/antena3fms35live-live/stream-lasexta_1" -W "http://www.antena3.com/static/swf/A3Player.swf" -p "http://www.lasexta.com/directo" -q -v > /tmp/$CANAL."$ID" & ;;

	Cuatro) rtmpdump -r "rtmp://live3.flashstreaming.mobi/live?token=2qwPJ0s-KwJfZ1V5N-rZ-AExpired=1390857763" -a "live?token=2qwPJ0s-KwJfZ1V5N-rZ-AExpired=1390857763" -f "LNX 11,2,202,332" -W "http://flashstreaming.mobi/embed/noreproductor.php?o=1&kpublica=29245" -p "http://flashstreaming.mobi" -y "divin3ef815416f775098fe977004015c6193" -q -v > /tmp/$CANAL."$ID" & ;;

	Tele5) rtmpdump -m 200 -a "app" -r "rtmp://46.19.140.242/app" -y "16293" -W "http://www.udemy.com/static/flash/player5.9.swf" -p "http://www.shidurlive.com/stream/4e6d55324f5463304e7a49325a673d3d/48d4c5836294" -q > /tmp/$CANAL."$ID" & ;;

	Xplora) rtmpdump -r "rtmp://live1.freelivetv.tv/live?token=0f5LvTBaiLjTHUt7Nxbl8AExpired=1390856336" -a "live?token=0f5LvTBaiLjTHUt7Nxbl8AExpired=1390856336" -f "LNX 11,2,202,332" -W "http://freelivetv.tv/embed/noreproductor.php?o=1&kpublica=68100" -p "http://freelivetv.tv" -y "xploras" -q -v > /tmp/$CANAL."$ID" & ;;

	Nitro) rtmpdump -m 200 -a "live" -r "rtmp://live.flashstreaming.mobi:1935/live" -y "c4ca4238a0b923820dcc509a6f75849b" -W "http://flashstreaming.mobi/embed/reproductor.php?o=1" -p "http://flashstreaming.mobi/embed/embed.php?channel=nitros_verlatelegratis_com&w=650&h=400"  -q -v > /tmp/$CANAL."$ID" & ;;

	Neox)  rtmpdump -r "rtmp://50.7.181.90/iguide" -y "p62u8lplaq5xtoe" -W "http://cdn.iguide.to/player/secure_player_iguide_embed_token.swf" -p "http://www.iguide.to/"  -T "#ed%h0#w18623jsda6523lDGDve" -q -v > /tmp/$CANAL."$ID" & ;;

	La_Sexta_3) rtmpdump -m 200 -r "rtmp://174.36.251.140/live/lasexta3lacaja?id=15912" -W "http://www.ucaster.eu/static/scripts/eplayer.swf" -p "http://schuster92.com" -C S:OK -q > /tmp/$CANAL."$ID" & ;;

	Paramount) rtmpdump -r "rtmp://streaming.freelivetv.tv:1935/live" -y "comedycfcd208495d565ef66e7dff9f98764da" -W "http://freelivetv.tv/embed/reproductor.php?o=1" -p "http://freelivetv.tv/embed/embed.php" -C S:OK -v -q > /tmp/$CANAL."$ID" & ;;

	Intereconomia) rtmpdump -m 200 -r "rtmp://media.intereconomia.com/live/intereconomiatv1" -q -v > /tmp/$CANAL."$ID" & ;;

	BusinessTV) rtmpdump -m 200 -r "rtmp://media.intereconomia.com/live" -y "business1" -W "ttp://www.intereconomia.com/flowplayer-3.2.5.swf?0.19446.067378316934" -p "http://www.intereconomia.com/ver-intereconomia-business-tv"  -q -v > /tmp/$CANAL."$ID" & ;;

	13TV) rtmpdump -m 200 -r "rtmp://xiiitvlivefs.fplive.net/xiiitvlive-live" -y "stream13tv" -W "http://static.hollybyte.com/public/players/flowplayer/swf/flowplayer.commercial.swf" -p "http://live.13tv.hollybyte.tv/embed/4f33a91894a05f5f49020000" -q -v > /tmp/$CANAL."$ID" & ;;

	Energy) rtmpdump -r "rtmp://live1.freelivetv.tv/live?token=5us5IWzLxUE5ueU2e1TglQExpired=1390852981" -a "live?token=5us5IWzLxUE5ueU2e1TglQExpired=1390852981" -f "LNX 11,2,202,332" -W "http://freelivetv.tv/embed/noreproductor.php?o=1&kpublica=68100" -p "http://freelivetv.tv" -y "2838023a778dfaecdc212708f721b788" -C S:OK -q -v > /tmp/$CANAL."$ID" & ;;

	FDF) rtmpdump -r "rtmp://live1.freelivetv.tv/live?token=5us5IWzLxUE5ueU2e1TglQExpired=1390852981" -a "live?token=5us5IWzLxUE5ueU2e1TglQExpired=1390852981" -f "LNX 11,2,202,332" -W "http://freelivetv.tv/embed/noreproductor.php?o=1&kpublica=68100" -p "http://freelivetv.tv" -y "2838023a778dfaecdc212708f721b788"  -C S:OK -q -v > /tmp/$CANAL."$ID" & ;;

	Aragon_TV) rtmpdump -m 200 -r "rtmp://aragontvlivefs.fplive.net/aragontvlive-live" -y "stream_normal_abt" -W "http://alacarta.aragontelevision.es/streaming/flowplayer.commercial-3.2.7.swf" -p "http://alacarta.aragontelevision.es/streaming/streaming.html" -q -v > /tmp/$CANAL."$ID" & ;;

	# IberoamericaTV) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "rtsp://cdns724ste1010.multistream.net:80/iberoamericatvlive/Continuidad-500"  > /dev/null 2>&1 & mplayer_conf_change ;; 

	IberoamericaTV) cvlc -q "rtsp://cdns724ste1010.multistream.net:80/iberoamericatvlive/Continuidad-500" --sout=file/ts:/tmp/$CANAL."$ID" > /dev/null 2>&1 & mplayer_conf_change ;;

	Huesca_TV) rtmpdump -m 200 -r "rtmp://streaming2.radiohuesca.com/live/" -W "http://player.longtailvideo.com/player5.3.swf" -y "huescatv" -p "http://www.intertelevision.com/spain/localiatv.php" -v > /tmp/$CANAL."$ID" & ;;

	Galicia_TV_EU) rtmpdump -m 200 -r "rtmp://media3.crtvg.es:80/live" -y "tvge_2" -W "http://www.crtvg.es/flowplayer3/flowplayer.commercial-3.2.7.swf" -p "http://www.crtvg.es/tvg/tvg-en-directo" -q -v > /tmp/$CANAL."$ID" & ;;

	Galicia_TV_AM) rtmpdump -m 200 -r "rtmp://media3.crtvg.es:80/live" -y "tvga_2" -W "http://www.crtvg.es/flowplayer3/flowplayer.commercial-3.2.7.swf" -p "http://www.crtvg.es/tvg/tvg-en-directo/canle/galicia-tv-america" -q -v > /tmp/$CANAL."$ID"  & ;;

	Teleminho) rtmpdump -m 200 -a "teleminho" -r "rtmp://fcs.grupo5.com/teleminho/" -y "telemiño" -W "http://www.grupo5.com/fcs/teleminho/teleminho.swf" -p "http://www.teleminho.com/" -q -v > /tmp/$CANAL."$ID"  & ;;

	Canarias) rtmpdump -m 200 -r "rtmp://streamrtvc.mad.idec.net/rtvc1" -y "rtvc_1.sdp" -W "http://www.rtvc.es/swf/flowplayer.commercial-3.1.5.swf" -p "http://www.rtvc.es/television/enDirecto.aspx?canal=tv" -q -v > /tmp/$CANAL."$ID" & ;;

	Canarias_NET) rtmpdump -m 200 -r "rtmp://streamrtvc.mad.idec.net:1935/rtvcnet/" -y "rtvc_net.sdp" -W "http://www.rtvc.es/swf/flowplayer.commercial-3.1.5.swf" -p "http://www.rtvc.es/television/enDirecto.aspx?canal=tv" -q -v > /tmp/$CANAL."$ID" & ;;

	Lancelot) rtmpdump -m 200 -a "directo" -r "rtmp://5.135.177.210/directo" -y "lancelot" -W "http://www.lancelot.tv/directo/player.swf" -p "http://www.lancelot.tv/directo/" -q -v > /tmp/$CANAL."$ID" & ;;

	Eldia_TV) rtmpdump -m 200 -r "rtmp://teledifusion.tv/dia" -y "dia" -W "http://www.eldia.tv/player.swf" -p "http://www.eldia.tv/" -q -v > /tmp/$CANAL."$ID" & ;;

	TVRioja) rtmpdump -m 200 -r "rtmp://teledifusion.tv/rioja" -y "rioja" -W "http://www.tvr.es/html5/player.swf" -p "http://www.tvr.es/directo.php" -q -v > /tmp/$CANAL."$ID" & ;;

	StvRioja) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" mms://www.riojasintonia.com/stv > /dev/null 2>&1 & mplayer_conf_change ;;

	TPA_a7) rtmpdump -m 200 -r "rtmp://teledifusion.tv:1935/asturiastv" -y "asturiastvlive" -W "http://www.rtpa.es/jwplayer/player.swf" -p "http://www.rtpa.es/television" -q -v > /tmp/$CANAL."$ID" & ;;

	Andalucia)  mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" http://195.10.10.220/rtva/andaluciatelevisionh264.flv > /dev/null 2>&1 & mplayer_conf_change ;;

	Huelva_TV) rtmpdump -m 200 -r "rtmp://flash3.todostreaming.es/huelvatv" -W "http://www.huelvatv.com/plugins/content/jw_allvideos/includes/js/mediaplayer/player.swf" -y "livestream" -p "http://huelvatv.com/index.php/en-directo" -q -v > /tmp/$CANAL."$ID" & ;;

	Abteve) rtmpdump -m 200 -r "rtmp://live.cycnet.eu/flvplayback" -y "ts_2_68_69" -W "http://www.abteve.com/live/flowplayer/flowplayer-3.2.11.swf" -p "http://www.abteve.com/abteve-on-line.htm" -q -v > /tmp/$CANAL."$ID" & ;;

	BarcelonaTV)  mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" http://195.10.10.207/barcelonatv/barcelonatv-high.flv  > /dev/null 2>&1 & mplayer_conf_change ;;
	
	IB3) rtmpdump -m 200 -r "rtmp://ib3tvlivefs.fplive.net/ib3tvlive-live" -y "streamib3" -W "http://ib3cdn.s3.amazonaws.com/player/player.swf" -p "http://ib3tv.com/ib3/player/ib3sat.php" -q -v > /tmp/$CANAL."$ID"  & ;;

	Canal9_24)  mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" http://195.10.10.213/rtvv/canal9.flv > /dev/null 2>&1 & mplayer_conf_change ;; 

	Onda_Azul) rtmpdump -m 200 -r "rtmp://ondaazullivefs.fplive.net:1935/ondaazullive-live/" -y "ondaazullive-stream1" -W "http://www.freeetv.com/script/mediaplayer/player.swf" -p "http://www.waaatch.com/modules.php?name=Video_Stream&page=watch&id=4690" -q -v > /tmp/$CANAL."$ID" & ;;

	TV3CAT) rtmpdump -m 200 -r "rtmp://tv-nogeo-flashlivefs.fplive.net/tv-nogeo-flashlive-live" -y "stream_TV3CAT_FLV" -W "http://www.tv3.cat/ria/players/3ac/evp/Main.swf" -p "http://www.tv3.cat/directes/" -q -v > /tmp/$CANAL."$ID" & ;;

	TV3) rtmpdump -m 200 -r "rtmp://tv-nogeo-flashlivefs.fplive.net/tv-nogeo-flashlive-live" -y "stream_TV3_FLV" -W "http://www.tv3.cat/ria/players/3ac/evp/Main.swf" -p "http://www.tv3.cat/directes/" -q -v > /tmp/$CANAL."$ID" & ;;

	TV3_24) rtmpdump -m 200 -r "rtmp://tv-nogeo-flashlivefs.fplive.net/tv-nogeo-flashlive-live" -y "stream_324_FLV" -W "http://www.tv3.cat/ria/players/3ac/evp/Main.swf" -p "http://www.tv3.cat/directes/" -q -v > /tmp/$CANAL."$ID" & ;;

	Canal_33) rtmpdump -m 200 -r "rtmp://tv-nogeo-flashlivefs.fplive.net/tv-nogeo-flashlive-live" -y "stream_33D_FLV" -W "http://www.tv3.cat/ria/players/3ac/evp/Main.swf" -p "http://www.tv3.cat/directes/" -q -v > /tmp/$CANAL."$ID" & ;;

	Esport3) rtmpdump -m 200 -r "rtmp://tv-nogeo-flashlivefs.fplive.net/tv-nogeo-flashlive-live" -y "stream_ES3_FLV" -W "http://www.tv3.cat/ria/players/3ac/evp/Main.swf" -p "http://www.tv3.cat/directes/" -q -v > /tmp/$CANAL."$ID" & ;;

	Super3) rtmpdump -m 200 -r "rtmp://tv-nogeo-flashlivefs.fplive.net/tv-nogeo-flashlive-live" -y "stream_33D_FLV" -W "http://www.tv3.cat/ria/players/3ac/evp/Main.swf" -p "http://www.tv3.cat/3alacarta/#/directes/SUPER3" -q -v > /tmp/$CANAL."$ID" & ;;

	TeleB) rtmpdump -m 200 -r "rtmp://directe.tvbadalona.cat/live" -y "myStream.sdp" -W "http://www.teleb.cat/directe/flowplayer-3.2.5.swf" -p "http://www.teleb.cat/directe/" -q -v > /tmp/$CANAL."$ID" & ;;

	TV_Girona) rtmpdump -m 200 -r "rtmp://81.95.0.67:19935/tvgirona" -y "directe" -W "http://www.ixac.tv/rtmp/flowplayer.commercial-3.2.5.swf" -p "http://www.ixac.tv/rtmp/tvgirona_Vidal_player_independent_E.html" -q -v > /tmp/$CANAL."$ID" & ;;

	Canal_8) rtmpdump -m 200 -r "rtmp://94.23.54.177/8TV" -y "8aldia-directe" -W "http://css01.mundodeportivo.com/imagenes/players/player.swf" -p "http://narrowcast.lavanguardia.com" -q -v > /tmp/$CANAL."$ID" & ;;

	VoTV) rtmpdump -m 200 -r "rtmp://xiptv-streaming.gnuine.com/ocasional5" -y "directe" -W "http://votv.xiptv.cat/flash/flowplayer.commercial-3.2.11.swf" -p "http://votv.xiptv.cat" -q -v > /tmp/$CANAL."$ID" & ;;

	TVCS) rtmpdump -m 200 -r "rtmp://188.165.230.206/directo" -y "livestream" -W "http://www.tvcs.tv/skins2.3.5/awes/player.swf" -p "http://www.tvcs.tv/endirecto/" -q -v > /tmp/$CANAL."$ID" & ;;

	Ribera_TV) rtmpdump -m 200 -r "rtmp://flash3.todostreaming.es/ribera" -y "livestream" -W "http://www.todostreaming.es/player_new.swf" -p "http://www.riberatelevisio.com" -q -v > /tmp/$CANAL."$ID" & ;;

	Telemadrid_SAT) rtmpdump -m 200 -r "rtmp://cp118140.live.edgefcs.net:1935/live" -y "TSAtelemadridsat@47720" -q -v > /tmp/$CANAL."$ID" & ;;

	Telemadrid_Otra) rtmpdump -m 200 -r "rtmp://cp96225.live.edgefcs.net:1935/live?videoId=292161053001&lineUpId=&pubId=104403117001&playerId=111868723001&.affiliateId=" -W "http://admin.brightcove.com/viewer/us20130118.1025/federatedVideoUI/BrightcovePlayer.swf" -y "Laotra@30799" -p "http://www.telemadrid.es/?q=emision_en_directo_laotra" -q -v > /tmp/$CANAL."$ID" & ;;

	Cyl7) rtmpdump -m 200 -r "rtmp://live1.nice264.com:1935/niceStreamingServer/_definst_/cyl_cyltv_live|rtmp://live2.nice264.com:1935/niceStreamingServer/_definst_/cyl_cyltv_live" -a "niceLiveServer"  -W "http://mgmt.nice264.com/swf/jwplayer.swf" -p "http://www.rtvcyl.es/Directo.aspx" -q -v > /tmp/$CANAL."$ID" & ;;

	Etb_SAT) rtmpdump -m 200 -r "rtmp://cp70268.live.edgefcs.net/live" -y "eitb-ETBSat@5219" -W "http://www.eitb.com/resources/flash/video_playerberria3.swf" -p "http://www.eitb.com/es/television/etb-sat/" -q -v > /tmp/$CANAL."$ID" & ;;

	Canal_Vasco) rtmpdump -m 200 -r "rtmp://cp70268.live.edgefcs.net/live" -y "eitb-CanalVasco@5519" -W "http://www.eitb.com/resources/flash/video_player.swf" -p "http://www.eitb.com/es/television/canal-vasco/" -q -v > /tmp/$CANAL."$ID" & ;;

	TeleBilbao) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "telebilbao.stream" -W "http://www.lasteles.com/js/mediaplayer-5.8/player.swf" -p "http://www.lasteles.com/es/player.php?auto=0&id=14884" -q -v > /tmp/$CANAL."$ID" & ;;

	Divinity) rtmpdump -r "rtmp://live3.flashstreaming.mobi/live?token=2qwPJ0s-KwJfZ1V5N-rZ-AExpired=1390857763" -a "live?token=2qwPJ0s-KwJfZ1V5N-rZ-AExpired=1390857763" -f "LNX 11,2,202,332" -W "http://flashstreaming.mobi/embed/noreproductor.php?o=1&kpublica=29245" -p "http://flashstreaming.mobi" -y "divin3ef815416f775098fe977004015c6193" -v -q > /tmp/$CANAL."$ID" &;;

	Discovery_Channel) rtmpdump -r "rtmp://live1.freelivetv.tv/live?token=v-rmsmc_olqqcCygFFJwtAExpired=1390856051" -a "live?token=v-RMSmc_OlQqcCygFFJwtAExpired=1390856051" -f "LNX 11,2,202,332" -W "http://freelivetv.tv/embed/noreproductor.php?o=1&kpublica=68100" -p "http://freelivetv.tv" -y "discovery1" -v -q > /tmp/$CANAL."$ID" & ;;

	TNT) rtmpdump -r "rtmp://146.185.25.228/live" -y "tnthd78?id=8424" -W "http://www.ezcast.tv/static/scripts/eplayer.swf" -p "http://www.ezcast.tv/embedded/tnthd78/1/650/400" -C S:OK -q -v > /tmp/$CANAL."$ID" & ;;

	Xtrm) rtmpdump -r "rtmp://live.streamingplus.mobi:1935/live" -y "xtrm" -W "http://www.longtailvideo.com/jwplayer/jwplayer.flash.swf" -p "http://streamingplus.mobi/embed.php" -C S:OK -q -v > /tmp/$CANAL."$ID" & ;;

	SyFy) rtmpdump -r "rtmp://149.255.37.164/stream" -y "lcamphd2?id=108587" -W "http://www.liveflash.tv/resources/scripts/eplayer.swf" -p "http://www.liveflash.tv/embedplayer/lcamphd2/1/650/400" -C S:OK -q -v > /tmp/$CANAL."$ID" & ;;

	Cosmo) rtmpdump -r "rtmp://5.63.146.236/live" -y "cosmo11?id=183445" -W "http://mips.tv/content/scripts/eplayer.swf" -p "http://mips.tv/embedplayer/cosmo11/1/650/400" -C S:OK -q -v > /tmp/$CANAL."$ID" & ;;

	Calle13) rtmpdump -r "rtmp://live1.freelivetv.tv/live?token=qIbWfHZECSyY0fqGmpTToQExpired=1390857297" -a "live?token=qIbWfHZECSyY0fqGmpTToQExpired=1390857297" -f "LNX 11,2,202,332" -W "http://freelivetv.tv/embed/noreproductor.php?o=1&kpublica=68100" -p "http://freelivetv.tv" -y "calle131" -C S:OK -q -v > /tmp/$CANAL."$ID" & ;;
	
	Hollywood) rtmpdump -m 200 -r "rtmp://streaming.freelivetv.tv:1935/live" -y "182be0c5cdcd5072bb1864cdee4d3d6e"  -W "http://freelivetv.tv/embed/noreproductor.php?o=1" -p "http://freelivetv.tv/embed/embed.php?channel=hollywood&w=650&h=400" -C S:OK -q -v > /tmp/$CANAL."$ID" & ;;

	Historia) rtmpdump -r "rtmp://live1.freelivetv.tv/live?token=a6Lerqlak7j4kI9DbqCpzQExpired=1390857665" -a "live?token=a6Lerqlak7j4kI9DbqCpzQExpired=1390857665" -f "LNX 11,2,202,332" -W "http://freelivetv.tv/embed/noreproductor.php?o=1&kpublica=68100" -p "http://freelivetv.tv" -y "historia1" -q -v > /tmp/$CANAL."$ID" & ;;

	MTV) rtmpdump -m 200 -r "rtmp://185.2.138.108/live" -y "mtvhd?id=1179" -W "http://www.ezcast.tv/static/scripts/eplayer.swf" -p "http://www.ezcast.tv/embedded/mtvhd/1/650/400" -C S:OK -q -v > /tmp/$CANAL."$ID" & ;;
	
	Eurosport) ffmpeg -loglevel panic -i "http://esioslive-i.akamaihd.net/hls/live/201630/AL_ESP1_SP_SPA/playlist_1800.m3u8" -f flv -acodec copy -vcodec copy /tmp/$CANAL."$ID"  > /dev/null 2>&1 & ;;
	
	Canal_Extremadura) rtmpdump -m 200 -r "rtmp://canalextremaduralive.cdn.canalextremadura.es/canalextremaduralive-live/" -y "stream001" -W "http://www.canalextremadura.es/sites/all/modules/custom/slx_reproductor/js/mediaplayer-5.7/player.swf" -p "http://www.canalextremadura.es/alacarta/tv/directo" -q -v > /tmp/$CANAL."$ID" & ;;

	KissTV) rtmpdump -m 200 -r "rtmp://kisstelevision.es.flash3.glb.ipercast.net/kisstelevision.es-live" -y "live" -W "http://kisstelevision.en-directo.com/kisstelevision_avw.swf" -p "http://www.kisstelevision.es" -q -v > /tmp/$CANAL."$ID" & ;;

	UnaCadiz) rtmpdump -m 200 -r "rtmp://flash3.todostreaming.es/unatv" -y "live" -W "http://www.todostreaming.es/player_new.swf" -p "http://www.unacadiz.tv/directo/" -q -v > /tmp/$CANAL."$ID" & ;;

	UnaCordoba) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "unacordoba.stream" -W "http://www.lasteles.com/js/mediaplayer-5.8/player.swf" -q -v > /tmp/$CANAL."$ID" & ;;

	LUX_Mallorca) rtmpdump -m 200 -r "rtmp://fl1.viastreaming.net/canal37" -W "http://fl1.viastreaming.net:8000/player/player.swf" -y "livestream" -p "http://luxmallorca.tv/" -q -v > /tmp/$CANAL."$ID" & ;;

	RtvCE) rtmpdump -m 200 -r "rtmp://flash3.todostreaming.es/rtvceuta" -y "livestream" -W "http://www.todostreaming.es/player.swf" -p "http://www.rtvce.es/" -q -v > /tmp/$CANAL."$ID" & ;;

	TVMelilla) rtmpdump -m 200 -r "rtmp://stream.tvmelilla.es:1935/tvmelilla" -y "live" -W "http://www.tvmelilla.es/jwplayer/player.swf" -p "http://www.tvmelilla.es/directo.html" -q -v > /tmp/$CANAL."$ID" & ;;

	EuroNews_ES) rtmpdump -m 200 -r "rtmp://fr-par-1.stream-relay.hexaglobe.net:1935/rtpeuronewslive" -y "es_video350_flash_all.sdp" -W "http://es.euronews.com/media/player_live_1_14.swf" -p "http://es.euronews.com/noticias/en-directo/" -q -v > /tmp/$CANAL."$ID" & ;;
	
	France24) rtmpdump -m 200 -r "rtmp://vipwowza.yacast.net/france24_live_en" -y "f24_liveen.stream" -W "http://www.france24.com/en/sites/all/modules/maison/aef_player/flash/player_new.swf" -p "http://www.france24.com" -q -v > /tmp/$CANAL."$ID"  & ;;

	PressTV) rtmpdump -m 200 -r "rtmp://cp140005.live.edgefcs.net:80/live" -y "PressTV_RTMP_4@87306" -p "http://www.presstv.ir" -q -v > /tmp/$CANAL."$ID" & ;;

	VaughanTV) rtmpdump -m 200 -a "vaughantvlive-live/" -r "rtmp://vaughantvlivefs.fplive.net/vaughantvlive-live/" -y "vaughantv_1" -W "http://vaughantv.cdn.customers.overon.es/player/player.swf" -p "http://www.vaughanradio.com" -q -v > /tmp/$CANAL."$ID" & ;;

	Russian_Today) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "russiantoday.stream" -q -v > /tmp/$CANAL."$ID" & ;;

	TeleSur) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "telesur.stream" -q -v > /tmp/$CANAL."$ID" & ;;

	AtelTV) rtmpdump -m 200 -r "rtmp://edge.wms28.lorini.net/ateltv/" -y "ateltv" -W "http://www.lorini.net/playerv/player.swf" -p "http://www.lorini.net" -q -v > /tmp/$CANAL."$ID" & ;;

	DatTV) rtmpdump -m 200 -a "ustream2live-live/" -r "rtmp://ustreamlivefs.fplive.net:1935/ustream2live-live/" -y "stream_live_1_1_4172359" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:353.swf" -p "http://www.ustream.tv" -q -v > /tmp/$CANAL."$ID" & ;;

	VTV) rtmpdump -m 200 -a "vtvdsl" -r "rtmp://edg.ord.movipbox2.streamguys.net/vtvdsl" -y "vtvdsl.sdp" -W "http://www.vtv.gob.ve/player.swf" -p "http://www.vtv.gob.ve"  -q -v > /tmp/$CANAL."$ID" & ;;

	IslaTV) rtmpdump -m 200 -r "rtmp://edge.wms28.lorini.net/islatv/" -y "islatv" -W "http://www.lorini.net/playerv/player.swf" -p "http://www.islatv.com.ve" -q -v > /tmp/$CANAL."$ID" & ;;

	PromarTV) rtmpdump -m 200 -r "rtmp://edge.wms28.lorini.net/promartv/" -y "promartv" -W "http://www.lorini.net/playerv/player.swf" -p "http://www.lorini.net"  -q -v > /tmp/$CANAL."$ID" & ;;

	Telebahia) rtmpdump -m 200 -r "rtmp://62.42.17.93:1935/live" -y "Live" -W "http://www.telebahia.tv/player/player.swf" -q -v > /tmp/$CANAL."$ID" & ;;

	ImasTV) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "imastv.stream" -q -v > /tmp/$CANAL."$ID" & ;; 
	
	ZaragozaTV) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "ztv.stream" -q -v > /tmp/$CANAL."$ID" & ;;
	
	TeleToledo) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "teletoledo.stream" -q -v > /tmp/$CANAL."$ID" & ;;

	Huelva_CNH) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "cnh.stream" -q -v > /tmp/$CANAL."$ID" & ;;

	LevanteTV) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "levantetv.stream" -q -v > /tmp/$CANAL."$ID" & ;;	

	InformacionTV) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "informaciontv.stream" -q -v > /tmp/$CANAL."$ID" & ;;

	PTV_Malaga) rtmpdump -m 200 -r "rtmp://149.11.34.6/rtplive" -y "ptvmalaga.stream" -q -v > /tmp/$CANAL."$ID" & ;;
	
	CostadelSol_TV) rtmpdump -m 200 -r "rtmp://fl0.c80177.cdn.qbrick.com:1935/80177/_definst_" -y "20242994"  -p "http://www.costadelsoltv.com" -q -v > /tmp/$CANAL."$ID"  & ;;

	M95TV) rtmpdump -m 200 -r "rtmp://movipbox.streamguys.net:1935/m95tv/" -y "m95tv.sdp" -W "http://www.m95tv.es/modules/mod_playerjr/player-licensed5.swf" -p "http://www.m95tv.es" -q -v > /tmp/$CANAL."$ID" & ;;

	Humorbox) rtmpdump -m 200 -r "rtmp://musicbox.cdnvideo.ru/musicbox-live" -y "humorbox.sdp" -W "http://www.musicboxtv.ru/_front/flowplayer-3.2.7.swf" -p "http://www.musicboxtv.ru" -q -v > /tmp/$CANAL."$ID" & ;;
	
	MusicBox) rtmpdump -m 200 -r "rtmp://musicbox.cdnvideo.ru/musicbox-live" -y "musicbox.sdp" -W "http://www.musicboxtv.ru/_front/flowplayer-3.2.7.swf" -p "http://www.musicboxtv.ru" -q -v > /tmp/$CANAL."$ID" & ;;

	ShansonTV) rtmpdump -m 200 -r "rtmp://chanson.cdnvideo.ru/chanson-live/" -y "shansontv.sdp" -W "http://www.shanson.tv/jw/jwplayer.flash.swf" -p "http://www.shanson.tv" -q -v > /tmp/$CANAL."$ID" & ;;

	DeluxeMusic) rtmpdump -m 200 -r "rtmp://flash.cdn.deluxemusic.tv/deluxemusic.tv-live/" -y "web_850.stream" -q -v > /tmp/$CANAL."$ID" & ;;

	GoticaTV) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "gotica.stream" -q -v > /tmp/$CANAL."$ID" & ;;

	LobasTV) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "lobas.stream" -q -v > /tmp/$CANAL."$ID" & ;;

	PartyTV) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "partytv.stream" -q -v > /tmp/$CANAL."$ID" & ;;

	Unlove) rtmpdump -m 200 -r "rtmp://149.11.34.6/live" -y "unlovechannel.stream" -q -v > /tmp/$CANAL."$ID" & ;;

	Eska) rtmpdump -m 200 -r "rtmp://46.105.112.212:1935/live" -y "mpegts.stream" -q -v > /tmp/$CANAL."$ID" & ;;

	TV105) rtmpdump -m 200 -r "rtmp://fms.105.net:1935/live" -y "105Test1" -W "http://www.105.net/com/universalmind/swf/video_player_102.swf?xmlPath=/com/universalmind/tv/105/videoXML.xml&advXML=/com/universalmind/adsWizzConfig/0.xml" -p "http://www.105.net" -q -v > /tmp/$CANAL."$ID" & ;;

	RMC_TV) rtmpdump -m 200 -r "rtmp://fms.105.net:1935/live" -y "rmc1" -W "http://video.radiomontecarlo.net/com/universalmind/swf/videoPlayerAdsWizz01.swf?xmlPath=/com/universalmind/tv/rmc/videoXML.xml&advXML=/com/universalmind/adsWizzConfig/1.xml" -p "http://video.radiomontecarlo.net" -q -v > /tmp/$CANAL."$ID" & ;;

	LaBelleTV) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" mms://www.labelletv.net/labelleTV  > /dev/null 2>&1 & mplayer_conf_change ;;
	
	SoleilTV) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" mms://live240.impek.com/soleiltv  > /dev/null 2>&1 & mplayer_conf_change ;;

	Funtv) rtmpdump -m 200 -r "rtmp://creyden.popler.tv:80/publishlive?play=123452" -y "4funtv" -W "http://www.popler.tv/player/flowplayer.commercial.swf" -p "http://www.4fun.tv" -q -v > /tmp/$CANAL."$ID" & ;;

	RblTV) rtmpdump -m 200 -r "rtmp://poviss.popler.tv:1935/publishlive?play=123452" -y "rebeltv" -W "http://www.popler.tv/player/flowplayer.commercial.swf" -p "http://www.rbl.tv" -q -v > /tmp/$CANAL."$ID" & ;;

	StreetclipTV) rtmpdump -m 200 -r "rtmp://stream.streetclip.tv:1935/live" -y "low-stream" -W "http://www.streetclip.tv/fileadmin/Templates/Streetclip20.11/libs/flowplayer/flowplayer.commercial-3.2.10.swf" -p "http://www.streetclip.tv"  -q -v > /tmp/$CANAL."$ID" & ;;

	Hispan_TV) rtmpdump -m 200 -r "rtmp://mtv.fms-01.visionip.tv/live" -y "mtv-m_tv-live-25f-4x3-SDh" -W "http://embeddedplayer.visionip.tv/data/swf/8f44869de82046.059e9bf6e623ee1d54965/player.swf" -p "http://www.hispantv.com" -q -v > /tmp/$CANAL."$ID" & ;;

	Aljazeera_Eng) rtmpdump -m 200 -r "rtmp://aljazeeraflashlivefs.fplive.net:1935/aljazeeraflashlive-live" -y "aljazeera_eng_high" -W "http://admin.brightcove.com/viewer/us20121113.1511/federatedVideoUI/BrightcovePlayer.swf" -p "http://www.aljazeera.com/watch_now/" -q -v > /tmp/$CANAL."$ID" & ;;

	NASA) rtmpdump -a "ustreamCdn/flash94/6540154" -r "rtmp://flash59.gblx.tcdn.ustream.tv:1935/ustreamCdn/flash94/6540154" -y "streams/live_1" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:360.swf" -p "http://www.ustream.tv" -q -v > /tmp/$CANAL."$ID" & ;;

	Esne_TV) rtmpdump -m 200 -r "rtmp://69.60.121.166/live" -y "esne2" -W "http://elsembradorministries.com/esne/ESNE-TV/files/player.swf" -p "http://elsembradorministries.com/esne/ESNE-TV/esnetvenvivo.html" -q -v > /tmp/$CANAL."$ID" & ;;

	Astrocanalshop) rtmpdump -m 200 -r "rtmp://flash3.todostreaming.es/telelinea1" -W "http://www.todostreaming.es/player_new.swf" -y "mystream" -p "http://www.astrocanalshop.com/streaming.htm" -q -v > /tmp/$CANAL."$ID" & ;;

	Ondamex) rtmpdump -m 200 -r "rtmp://stream.visualnetworks.es:1935/str063" -y "live" -W "http://ondamex.com/ondamex.swf" -p "http://ondamex.com" -q -v > /tmp/$CANAL."$ID" & ;;

	CubaVision) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID"  mms://cubavision.cubasi.cu/Tvcubana > /dev/null 2>&1 & mplayer_conf_change ;;

	Panamericana) rtmpdump -m 200 -r "rtmp://demo5.iblups.com/demo" -y "nm5esQgmkT"  -W "http://iblups.com/playertvlive123456789panamericanatv.swf" -p "http://iblups.com/e_panamericanatv-490-320" -q -v > /tmp/$CANAL."$ID" & ;;

	Global_TV) rtmpdump -m 200 -r "rtmp://demo13.iblups.com/demo" -y "hTWNttHSsq" -W "http://iblups.com/playertvlive123456789globaltv.swf" -p "http://iblups.com/e_globaltv-490-33" -q -v > /tmp/$CANAL."$ID" & ;;

	ATV_Sur) rtmpdump -m 200 -r "rtmp://demo.iblups.com/demo" -y "yVUQhp8tNL" -W "http://iblups.com/playertvlive123456789.swf" -p "http://iblups.com/e_atvsur-400-330" -q -v > /tmp/$CANAL."$ID" & ;;

	AricaTV) rtmpdump -m 200 -a "aricatv/aricatvvivo" -r "rtmp://stream210.digitalproserver.com:443/aricatv/aricatvvivo" -y "livestream" -W "http://media.digitalproserver.com/dps_player.swf" -p "http://www.aricatv.com/" -q -v > /tmp/$CANAL."$ID" & ;;

	Canal2) rtmpdump -r "rtmp://v1.streamcontrolpanel.com:1935/canal2" -y "canal2" -W "http://player.pepago.com/detectorvd/StrobeMediaPlayback.swf" -p "http://player.pepago.com" -q -v > /tmp/$CANAL."$ID" & ;;

	Canal9) rtmpdump -m 200 -r "rtmp://stream210.digitalproserver.com:1935/c9/c9vivo/livestream1" -y "livestream1" -W "http://media.digitalproserver.com/dps_player.swf" -p "http://www.biobiotv.cl" -q -v > /tmp/$CANAL."$ID" & ;;

	Digital_Channel) rtmpdump -m 200 -r "rtmp://stream210.digitalproserver.com:443/dch/dchvivo" -y "livestream" -W "http://media.digitalproserver.com/dps_player.swf" -p "http://www.dch.tv" -q -v > /tmp/$CANAL."$ID" & ;;

	Enlace) rtmpdump -m 200 -r "rtmp://cdne.unored.com/enlace" -y "str.sdp" -W "http://tvportal2.unored.com/enlace/player5/player.swf" -p "http://tvportal2.unored.com"  -q -v > /tmp/$CANAL."$ID" & ;;

	Canal33) rtmpdump -m 200 -r "rtmp://crearchile.com/live" -y "mp4:canal33.mp4" -W "http://crearchile.com/player/player.swf" -p "http://www.canal33.cl/senal.php" -q -v > /tmp/$CANAL."$ID" & ;;

	TVinet) rtmpdump -m 200 -r "rtmp://tv01.pueblohost.com/tvinet" -y "tvinet" -W "http://tv01.pueblohost.com/system/misc/jwplayer/player.swf" -p "http://www.tvinet.cl/emergente.php" -q -v > /tmp/$CANAL."$ID" & ;;

	Itv) rtmpdump -m 200 -r "rtmp://184.82.37.10:1935/live" -y "itvp" -W "http://fpdownload.adobe.com/strobe/FlashMediaPlayback.swf" -p "http://www.itvpatagonia.cl/online.html" -q -v > /tmp/$CANAL."$ID" & ;;

	RedTV) rtmpdump -m 200 -a "redtv/redtvvivo" -r "rtmp://66.231.177.36/redtv/redtvvivo" -y "livestream1" -W "http://media.digitalproserver.com/dps_player.swf" -p "http://www.lared.cl/online/" -q -v > /tmp/$CANAL."$ID" & ;;

	MegaTV) rtmpdump -m 200 -r "rtmp://mega.lb.ztreaming.com:80/mega/" -y "megaJaeRa1xing.sdp" -W "http://www.mega.cl/website/js/flowplayer/3.2.2/swf/rtmp.swf" -p "http://www.mega.cl/senal-en-vivo/" -q -v > /tmp/$CANAL."$ID" & ;;

	MetroTV) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" http://190.196.9.186:8080/subtv > /dev/null 2>&1 & mplayer_conf_change ;;

	TVnuevotiempo) rtmpdump -m 200 -r "rtmp://play2go.tv:1935/live" -y "TVnuevotiempo" -W "http://play2go.tv/flowplayer/flowplayer.commercial-3.2.14.swf" -p "http://play2go.tv/live/flowplayer.html?stream=TVnuevotiempo" -q -v > /tmp/$CANAL."$ID" & ;;

	RTC) rtmpdump -m 200 -a "ustreamVideo/12775842" -r "rtmp://flash79.ustream.tv:1935/ustreamVideo/12775842" -y "streams/live_1" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:353.swf" -p "http://cormudesi.cl/RTC_TV.html" -q -v > /tmp/$CANAL."$ID" & ;;
	
	TVu) rtmpdump -m 200 -a "tvu/tvuvivo" -r "rtmp://190.196.10.194/tvu/tvuvivo" -y "livestream1" -W "http://media.digitalproserver.com/dps_player.swf" -p "http://www.tvu.cl/images/stories/online.php"  -q -v > /tmp/$CANAL."$ID" & ;;

	TVlota) rtmpdump -m 200 -a "tvlota/tvlotavivo" -r "rtmp://stream210.digitalproserver.com:443/tvlota/tvlotavivo" -y "livestream" -W "http://media.digitalproserver.com/dps_player.swf" -p "http://www.tvlota.cl/index.php?option=com_content&view=article&id=2&Itemid=6"  -q -v > /tmp/$CANAL."$ID" & ;;

	SenadoTV) rtmpdump -m 200  -r "rtmp://senadortmpr.janus.cl:80/senadotv" -y "senado600" -W "http://www.senado.cl/prontus_senado/js-local/jwplayer/player.swf" -p "http://www.senado.cl/prontus_senado/site/edic/base/port/tv_senado.html"  -q -v > /tmp/$CANAL."$ID" & ;;

	UNIACCTV) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" mms://media.uniacc.cl/canal34tv > /dev/null 2>&1 & mplayer_conf_change ;;

	UATV) rtmpdump -m 200  -a "live/uautonoma" -r "rtmp://190.196.29.26:1935/live/uautonoma" -y "uautonoma" -W "http://www.eltelontv.com/clientes/uautonoma/bolt.swf" -p "http://www.eltelontv.com/clientes/uautonoma/"  -q -v > /tmp/$CANAL."$ID" & ;;

	UMAGTV) rtmpdump -m 200  -a "grupozlive-live/" -r "rtmp://grupozlivefs.fplive.net/grupozlive-live/" -y "streamumagtv" -W "http://umagtv.ztreaming.cl/swf/player.swf" -p "http://umagtv.ztreaming.cl/"  -q -v > /tmp/$CANAL."$ID" & ;;

	Horas24) rtmpdump -m 200 -a "envivo_edge/" -r "rtmp://wow1.tvn.cl/envivo_edge/" -y "imagen3" -W "http://www.24horas.cl/skins/24horas/swf/flowplayer.cluster-3.2.3.swf" -p "http://www.24horas.cl/envivo/"  -q -v > /tmp/$CANAL."$ID" & ;;

	TamTV) rtmpdump -m 200  -a "tamtv/" -r "rtmp://edge.wms28.lorini.net/tamtv/" -y "tamtv" -W "http://tamtv.com.ve/tv/player.swf" -p "http://tamtv.com.ve"  -q -v > /tmp/$CANAL."$ID" & ;;

	TVes) rtmpdump -m 200  -a "tves" -r "rtmp://movipbox.streamguys.net:1935/tves" -y "tves.sdp" -W "http://flash.telepuertovirtual.tv/tves-flash/player.swf" -p "http://www.tves.gob.ve" -q -v > /tmp/$CANAL."$ID" & ;;

	TicTV) rtmpdump -m 200  -a "tictv/" -r "rtmp://edge.wms28.lorini.net/tictv/" -y "tictv" -W "http://www.lorini.net/playerv/player.swf" -p "http://www.tictv.com.ve" -q -v > /tmp/$CANAL."$ID" & ;;

	TrpTV) rtmpdump -m 200  -a "trptv/" -r "rtmp://edge.wms28.lorini.net/trptv/" -y "trptv" -W "http://www.lorini.net/playerv/player.swf" -p "http://www.lorini.net"  -q -v > /tmp/$CANAL."$ID" & ;;

	TVO) rtmpdump -m 200 -a "tvo/" -r "rtmp://edge.wms28.lorini.net/tvo/" -y "tvo" -W "http://www.lorini.net/playerv/player.swf" -p "http://www.lorini.net/streaming/clientes/tvo.htm" -q -v > /tmp/$CANAL."$ID" & ;;

	Cetelmon_TV) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID"  http://tense.dyndns.org:8207 > /dev/null 2>&1 & mplayer_conf_change ;;  

	SolidariaTV) rtmpdump -m 200 -r "rtmp://flash3.todostreaming.es/solidariatv" -y "mystream" -W "http://www.todostreaming.es/player_new.swf" -p "http://www.solidariatv.com" -q -v > /tmp/$CANAL."$ID" & ;;

	RedBull) rtmpdump -m 200 -r "rtmp://cp93704.live.edgefcs.net/live/" -y "redbull1@21839" -W "http://www.chanfeed.com/streams/mediaplayer.swf" -p "http://chanfeed.com/red-bull-sport" -q -v > /tmp/$CANAL."$ID" & ;;

	TileSport) rtmpdump -m 200 -r "rtmp://tv1.streampulse.eu/tilesport" -y "movie1" -W "http://www.tilesport.tv/jwplayer/player.swf" -p "http://www.tilesport.tv" -q -v > /tmp/$CANAL."$ID" & ;;

	Al_Iraqiya_Sports) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" mms://212.7.196.74/sport > /dev/null 2>&1 & mplayer_conf_change ;;
	
	SportItalia) rtmpdump -m 200 -r "rtmp://94.32.97.9/streamit" -y "solocalciolive" -W "http://sportitalia24.twww.tv/embed.swf"  -q -v > /tmp/$CANAL."$ID" & ;;

	SkyPoker) rtmpdump -m 200 -r "rtmp://92.122.49.165:1935/live?_fcs_vhost=cp67698.live.edgefcs.net&akmfv=1.8" -y "SkyPoker_500k@9124" -W "http://www.skypoker.com/img/cms/live_tv_player.swf" -p "http://www.skypoker.com" -q -v > /tmp/$CANAL."$ID" & ;;

	ArgentinisimaTV) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID"  http://tense.dyndns.org:8207 > /dev/null 2>&1 & mplayer_conf_change ;;

	Canal10) rtmpdump -m 200 -a "ustreamVideo/11028856" -r "rtmp://flash74.ustream.tv:1935/ustreamVideo/11028856" -y "streams/live_1" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:353.swf" -p "http://www.cba24n.com.ar"  -q -v > /tmp/$CANAL."$ID" & ;;

	CBA24) rtmpdump -m 200 -a "ustreamVideo/11678041" -r "rtmp://flash83.ustream.tv:1935/ustreamVideo/11678041" -y "streams/live_1" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:353.swf" -p "http://www.cba24n.com.ar"  -q -v > /tmp/$CANAL."$ID" & ;;

	Canal21) rtmpdump -m 200 -a "canal21" -r "rtmp://184.173.6.168:1935/canal21" -y "h264live.f4v" -W "http://fpdownload.adobe.com/strobe/FlashMediaPlayback_101.swf" -p "http://arzbaires.c21tv.com.ar" -q -v > /tmp/$CANAL."$ID" & ;;

	Canal3)  mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" mms://201.251.124.171:1021 > /dev/null 2>&1 & mplayer_conf_change ;;

	Canal5) rtmpdump -m 200 -a "ustreamCdn/flash68/199131" -r "rtmp://flash98.xo.tcdn.ustream.tv:1935/ustreamCdn/flash68/199131" -y "streams/live_1" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:353.swf" -p "http://www.ustream.tv" -q -v > /tmp/$CANAL."$ID" & ;;  

	Canal7) rtmpdump -m 200 -a "live/c7" -r "rtmp://cms.tvsiete.tv/live/c7" -y "mp4:canal" -W "http://cms.tvsiete.tv/tools/mediaplayer/pla.swf" -p "http://www.tvsiete.tv" -q -v > /tmp/$CANAL."$ID" & ;;

	Canal_9) rtmpdump -m 200 -a "live/c9" -r "rtmp://www.canal9comodoro.com/live/c9" -y "mp4:canal" -W "http://www.canal9comodoro.com/mediaplayer/pla.swf" -p "http://www.canal9comodoro.com" -q -v > /tmp/$CANAL."$ID" & ;;  

	Canal_Provincial) rtmpdump -m 200 -a "live" -r "rtmp://190.2.58.90/live" -y "telered" -W "http://190.105.0.71/stream/jwplayer/player.swf" -p "http://www.canalprovincial.com.ar"  -q -v > /tmp/$CANAL."$ID" & ;;

	El_Rural)  rtmpdump -m 200 -a "live/crural" -r "rtmp://streamrural.cmd.com.ar/live/crural" -y "rural1" -W "http://www.elrural.com/sites/default/files/jwplayermodule/player/player.swf" -p "http://www.elrural.com"  -q -v > /tmp/$CANAL."$ID" & ;;

	El_trece) rtmpdump -m 200 -a "live13/13tv" -r "rtmp://stream.eltrecetv.com.ar/live13/13tv" -y "13tv1" -p "http://www.eltrecetv.com.ar"  -C S:OK -q -v > /tmp/$CANAL."$ID" & ;;

	Construir_TV) rtmpdump -m 200 -a "ustreamVideo/9143107" -r "rtmp://flash80.ustream.tv:1935/ustreamVideo/9143107" -y "streams/live_1" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:353.swf" -p "http://www.construirtv.com"  -q -v > /tmp/$CANAL."$ID" & ;;

	PakaPaka) rtmpdump -m 200  -r "rtmp://92.122.49.116:1935/live?_fcs_vhost=cp54218.live.edgefcs.net&uu.id=fj5159u7" -y "Canal_Encuentro_3@68921" -W "http://player.multicastmedia.com/templates/livefull2.swf" -p "http://player.multicastmedia.com" -q -v > /tmp/$CANAL."$ID" & ;;

	QMusica) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" mms://streamqm.uigc.net/qmusica > /dev/null 2>&1 & mplayer_conf_change ;;

	Canal26) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" http://200.115.194.1:8080/Canal26 > /dev/null 2>&1 & mplayer_conf_change ;;

	N9) rtmpdump -m 200 -a "ustreamVideo/4009255" -r "rtmp://flash58.ustream.tv:1935/ustreamVideo/4009255" -y "streams/live_1" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:353.swf" -p "http://www.noticiero9.com.ar/"  -q -v > /tmp/$CANAL."$ID" & ;;

	TN) rtmpdump -m 200  -a "live" -r "rtmp://stream.tn.com.ar/live" -y "tnmovil2" -W "http://tn.com.ar/sites/all/themes/dientuki/swf/dplayer/player.swf" -p "http://tn.com.ar"  -q -v > /tmp/$CANAL."$ID" & ;; 

	TN_2) rtmpdump -m 200  -a "live" -r "rtmp://stream.tn.com.ar/live" -y "tnhd1" -W "http://tn.com.ar/sites/all/themes/dientuki/swf/dplayer/player.swf" -p "http://tn.com.ar"  -q -v > /tmp/$CANAL."$ID" & ;; 

	Zona31) rtmpdump -m 200  -a "zona31" -r "rtmp://84.246.231.153/zona31" -y "zona31" -W "http://www.zona31.tv/player.swf" -p "http://www.zona31.tv" -q -v > /tmp/$CANAL."$ID" & ;;
	
	Canal13) rtmpdump -m 200 -a "ustreamCdn/flash72/1358413" -r "rtmp://flash89.xo.tcdn.ustream.tv:1935/ustreamCdn/flash72/1358413" -y "streams/live_1" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:353.swf" -p "http://www.ustream.tv/channel-popup/canal13riocuar.to" -q -v > /tmp/$CANAL."$ID" & ;;

	Canal10_Tucuman) rtmpdump -m 200 -a "live/8" -r "rtmp://200.85.152.45:1935/live/8" -y "stream" -W "http://www.g-video.org/embed.swf" -p "http://www.g-video.org/embed/8/425/351/FALSE/false" -q -v > /tmp/$CANAL."$ID" & ;;

	LapachoTV) rtmpdump -m 200 -r "rtmp://84.246.231.153/lapacho" -y "lapacho" -W "http://www.lapachotv.com.ar/jwplayer/player.swf" -p "http://www.lapachotv.com.ar/vivo/" -q -v > /tmp/$CANAL."$ID" & ;;

	FacetasDeportivas) rtmpdump -m 200 -a "live/_definst_" -r "rtmp://68.68.30.139/live/_definst_" -y "facetas1" -W "http://www.veemi.com/player/player-licensed.swf" -p "http://www.veemi.com/embed.php"  -q -v > /tmp/$CANAL."$ID" & ;;

	Cable_Noticias) rtmpdump -m 200 -a "live/" -r "rtmp://50.23.172.98:1935/live/" -y "cablenoticias" -W "http://www.cablenoticias.tv/player.swf" -p "http://www.cablenoticias.tv"  -q -v > /tmp/$CANAL."$ID" & ;;

	Canal_Tiempo) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "http://208.80.54.128/CANALELTIEMPO?streamtheworld_user=1&nobuf=1355954794813" > /dev/null 2>&1 & mplayer_conf_change ;;

	Tu_Kanal) rtmpdump -m 200 -a "ustreamVideo/10317018" -r "rtmp://flash81.ustream.tv:1935/ustreamVideo/10317018" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:353.swf" -y "streams/live_1" -p "http://www.ustream.tv" -q -v > /tmp/$CANAL."$ID" & ;;

	PyC) rtmpdump -m 200 -a "ustreamVideo/10554562" -r "rtmp://flash93.ustream.tv:1935/ustreamVideo/10554562" -y "streams/live_1" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:353.swf" -p "http://www.proyectosycomunicaciones.com"  -q -v > /tmp/$CANAL."$ID" & ;;

	Canal_Capital) rtmpdump -m 200 -a "ustream4live-live/" -r "rtmp://ustreamlivefs.fplive.net:1935/ustream4live-live/" -y "stream_live_1_1_9968011" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:353.swf" -p "http://www.ustream.tv"  -q -v > /tmp/$CANAL."$ID" & ;;

	CMB) rtmpdump -m 200 -a "cmbtv" -r "rtmp://4.30.20.151/cmbtv" -y "cmbtv1" -W "http://cpanel.netpatio.com/swfs/jwplayer/player.swf" -p "http://www.cmbcolombia.tv"  -q -v > /tmp/$CANAL."$ID" & ;;

	CristoVision) rtmpdump -m 200 -a "8008" -r "rtmp://wowzatv.paradigmaweb.com/8008" -y "8008" -W "http://www.cristovision.tv/player/playertv.swf" -p "http://www.cristovision.tv"  -q -v > /tmp/$CANAL."$ID" & ;;

	TeleVida) rtmpdump -m 200 -a "live" -r "rtmp://streaming3.vcb.com.co/live" -y "myStream" -W "http://eventos.vcb.com.co/mobile/player.swf" -p "http://eventos.vcb.com.co"  -q -v > /tmp/$CANAL."$ID" & ;;

	#RTVC) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "rtsp://cdns724ste1010.multistream.net:80/rtvclive/live-200" > /dev/null 2>&1 & mplayer_conf_change ;;
	RTVC) cvlc -q "rtsp://cdns724ste1010.multistream.net:80/rtvclive/live-200" --sout=file/ts:/tmp/$CANAL."$ID" > /dev/null 2>&1 & mplayer_conf_change ;;

	#RTVC2) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "rtsp://cdns724ste1010.multistream.net:80/rtvc2live/live-200" > /dev/null 2>&1 & mplayer_conf_change ;;
	RTVC2)  cvlc -q "rtsp://cdns724ste1010.multistream.net:80/rtvc2live/live-200" --sout=file/ts:/tmp/$CANAL."$ID" > /dev/null 2>&1 & mplayer_conf_change ;;

	#TeleCaribe) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "rtsp://cdns724ste1010.multistream.net:80/telecaribelive/live-200" > /dev/null 2>&1 & mplayer_conf_change ;;
	TeleCaribe) cvlc -q "rtsp://cdns724ste1010.multistream.net:80/telecaribelive/live-200" --sout=file/ts:/tmp/$CANAL."$ID" > /dev/null 2>&1 & mplayer_conf_change ;;

	#TelePacifico) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "rtsp://cdns724ste1010.multistream.net:80/telepacificolive/live-200" > /dev/null 2>&1 & mplayer_conf_change ;;

	TelePacifico)  cvlc -q  "rtsp://cdns724ste1010.multistream.net:80/telepacificolive/live-200"  --sout=file/ts:/tmp/$CANAL."$ID" > /dev/null 2>&1 & mplayer_conf_change ;;

	######

	RPC) rtmpdump -m 200 -a "live" -r "rtmp://74.222.1.108:1935/live" -y "canal13_hq.stream" -W "http://www.rpc.com.py/swf/player_web03.swf" -p "http://www.rpc.com.py"  -q -v > /tmp/$CANAL."$ID" & ;;

	Paravision) rtmpdump -m 200 -a "TV" -r "rtmp://83.170.79.14/TV" -y "paravisionext" -p "http://www.desdeparaguay.com" -q -v > /tmp/$CANAL."$ID" & ;;

	TeleFuturo) rtmpdump -m 200 -a "live" -r "rtmp://190.52.182.109:1935/live" -W "http://fpdownload.adobe.com/strobe/FlashMediaPlayback.swf" -y "myStream" -p "http://www.telefuturo.com.py" -q -v > /tmp/$CANAL."$ID" & ;;

	#####

	TelevisaHD) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "http://televisahdlive-f.akamaihd.net/gball01_1_475@56607"  > /dev/null 2>&1 & mplayer_conf_change ;;

	Milenio) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "http://brightcove03-f.akamaihd.net/milenio_centro_512k@51752"  > /dev/null 2>&1 & mplayer_conf_change ;;

	OnceTV) rtmpdump -m 200 -r "rtmp://www.oncetvmexicolive.tv:1935/livepkgr2" -y "int3" -W "http://www.oncetvmexicolive.tv/StrobeMediaPlayback.swf" -p "http://www.oncetvmexicolive.tv/internacional/" -q -v > /tmp/$CANAL."$ID" & ;;

	Canal66) rtmpdump -m 200 -a "canal66" -r "rtmp://unirtmp.tulix.tv:1935/canal66" -y "myStream.sdp" -W "http://www.streamwebtown.com/mediaplayer/player.swf" -p "http://giliboi.com/canal66/web/" -q -v > /tmp/$CANAL."$ID" & ;;

	Canal44) rtmpdump -m 200 -a "canal44" -r "rtmp://unirtmp.tulix.tv:1935/canal44" -y "myStream.sdp" -W "http://www.streamwebtown.com/mediaplayer/player.swf" -p "http://www.canal44.com/envivo.php" -q -v > /tmp/$CANAL."$ID" & ;;

	Congreso) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "rtsp://apreal03.triara.com/broadcast/canalcongreso.rm"  > /dev/null 2>&1 & mplayer_conf_change ;;

	Canal_Justicia) rtmpdump -m 200 -a "rtmplive" -r "rtmp://72.233.123.138:1936/rtmplive/" -y "/broadcast/scjnA1.mp4" -W "http://www.scjn.gob.mx/player/player.swf" -p "http://www.scjn.gob.mx/Paginas/transmision_vivo.aspx" -q -v > /tmp/$CANAL."$ID" & ;;

	Cortes_Diputados) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "rtsp://201.147.98.13:554/broadcast/sesion.rm"  > /dev/null 2>&1 & mplayer_conf_change ;; 

	Kanal_D) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "mms://beotelmedia.beotel.net/kanald"  > /dev/null 2>&1 & mplayer_conf_change ;;

	Sat7_Kids) mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "mms://wm1.sz.xlcdn.com/sz=SAT7=CYSAT7KIDS"  > /dev/null 2>&1 & mplayer_conf_change ;; 

	SmileofaChildTV) rtmpdump -m 200 -a "live" -r "rtmp://cp114426.live.edgefcs.net:1935/live?ovpfv=2.1.5" -y "smile_mbr_high_3@59409" -W "http://www.tbn.org/flash/hd_player_4x3.swf" -p "http://www.tbn.org"  -q -v > /tmp/$CANAL."$ID" & ;;

	Barbaraki_TV) rtmpdump -m 200  -r "rtmp://80.93.53.88:1935/live" -y "channel_6" -W "http://www.planeta-online.tv/planeta_player.swf" -p "http://www.planeta-online.tv" -q -v > /tmp/$CANAL."$ID" & ;;
	
	Minika_GO) rtmpdump -m 200 -r "rtmp://5.63.145.228:443/minika" -y "minika3" -W "http://i.tmgrup.com.tr/mnka/player/TMDMedia/TMDPlayer327.swf" -p "http://www.minika.com.tr" -q -v > /tmp/$CANAL."$ID" & ;;

	Minika_Cocuk )rtmpdump -m 200 -r "rtmp://198.105.211.4:443/minikacocuk" -y "minikacocuk3" -W "http://i.tmgrup.com.tr/mnka/player/TMDMedia/TMDPlayer327.swf" -p "http://www.minika.com.tr"  -q -v > /tmp/$CANAL."$ID" & ;;

	Yumurcak)  rtmpdump -m 200  -r "rtmp://eu01.kure.tv:80/liveedge" -y "yumurcak3" -W "http://web1.kure.tv/P/player_files/flowplayer.commercial-3.2.7.swf" -p "http://www.kure.tv" -q -v > /tmp/$CANAL."$ID" & ;;

	Gang_Cartoon_Channel)  mplayer -really-quiet -dumpstream -dumpfile /tmp/$CANAL."$ID" "mmsh://202.43.34.236/gan?server_time=1/17/2013%2010:22:04%20PM&hash_value=NUUej8agT0qDgDXQbJeIkw==&validminutes=480&MSWMExt=.asf"  > /dev/null 2>&1 & mplayer_conf_change ;;  

	RTS) rtmpdump -m 200 -a "vl/_definst_" -r "rtmp://96.44.149.50/vl/_definst_" -y "rtsonline88" -W "http://www.veemi.com/player/player-licensed.swf" -p "http://www.veemi.com/embed.php"  -q -v > /tmp/$CANAL."$ID" & ;;

	Canal1) rtmpdump -m 200 -a "vsharepulllive-live" -r "rtmp://vsharepulllivefs.vod.swiftcdn1.com:443/vsharepulllive-live" -y "18d0u2b661j" -W "http://vshare.tv/flash/player_209.swf" -p "http://www.canal1tv.com/" -q -v > /tmp/$CANAL."$ID" & ;;


	Ecuadortv) rtmpdump -m 200 -a "live" -r "rtmp://38.96.148.216:1935/live" -y "ecuadortvn" -W "http://www.ecuadortv.ec/mod_video/player.swf" -p "http://www.ecuadortv.ec/ecu.php?c=43" -q -v > /tmp/$CANAL."$ID" & ;;

	Oromar) rtmpdump -m 200 -a "ustreamVideo/10684956" -r "rtmp://flash82.ustream.tv:1935/ustreamVideo/10684956" -y "streams/live_1" -W "http://static-cdn1.ustream.tv/swf/live/viewer.rsl:360.swf" -p "http://www.ustream.tv/embed/10684956"  -q -v > /tmp/$CANAL."$ID" & ;;

	Canal7_KHSLV) rtmpdump -m 200 -a "live" -r "rtmp://216.231.129.50/live" -y "ipad.sdp" -W "http://www.canal7slp.com/wp-content/themes/canal7-clean_v2/mediaplayer/player.swf" -p "http://www.canal7slp.com/" -q -v > /tmp/$CANAL."$ID" & ;;
	
	TVazteca) ffmpeg -loglevel panic -i "http://ipd.tvazteca.net/azteca/_definst_/flv:1_p4n4a4m0_2@37527/playlist.m3u8" -f flv -acodec copy -vcodec copy /tmp/$CANAL."$ID"  > /dev/null 2>&1 & ;;
	
	TVazteca_news) ffmpeg -loglevel panic -i "http://ipd.tvazteca.net/live5/Noticias.smil/playlist.m3u8" -f flv -acodec copy -vcodec copy /tmp/$CANAL."$ID" > /dev/null 2>&1 & ;;

	*) echo -e "\n \e[00;36mBorrando ficheros temporales y saliendo,... \e[00m\n" && rm /tmp/versiontv /tmp/tvhelp > /dev/null 2>&1 ; exit ;;
esac



############################## Reproducir el streaming.

LASTPID=$(echo $!)
echo -e "\n * \e[00;36mConectando a $CANAL\e[00m\n"
sleep $CACHE_STREAMING

if [ -e /tmp/$CANAL."$ID" ]; then # Si existe, miramos el tamaño. Con mplayer, cuando no puede descargar el streaming, no crea el fichero.
	size=`du /tmp/$CANAL."$ID" | cut -f1`
else
	size=0
fi

if [ $KDE -eq 1 ]; then # Si KDE no está arrancado.

	if [ $size -lt 90 -a $fifo -eq 1 ]; then
		 echo -e " \e[00;31mError al conectar a $CANAL\e[00m\n"
		 zenity --no-wrap --error --text="No se ha podido establecer comunicación con el servidor de streaming de $CANAL" ;
		 rm /tmp/$CANAL."$ID" > /dev/null 2>&1 ;
		
	 else

		mplayer_keys &
		reproductor;
		
		if [ $SAVE -eq 0 -a $fifo -eq 1 ]; then
			zenity --question --text "¿Desea guardar el streaming de video en disco?" ;
	
			case $? in
   				0) mv /tmp/$CANAL."$ID" `zenity --file-selection --save` > /dev/null 2>&1 ;;
   			esac
		fi
	fi


elif [ $KDE -eq 0 ]; then # Si KDE está arrancado.


	if [ $size -lt 90 -a $fifo -eq 1 ]; then
		echo -e " \e[00;31mError al conectar a $CANAL\e[00m\n"
		kdialog --title 'Fallo al conectar' --error "No se ha podido establecer comunicación con el servidor de streaming de $CANAL" ;
		rm /tmp/$CANAL."$ID" > /dev/null 2>&1 ;
	else
		mplayer_keys &
		reproductor;
	
		if [ $SAVE -eq 0 ]; then	
			kdialog --yesno "¿Desea guardar el streaming de video en disco?" ;
	
			case $? in
   				0) mv /tmp/$CANAL."$ID" `kdialog --getsavefilename $HOME` > /dev/null 2>&1 ;;
   			esac
		fi
	fi



fi

############################## Desconectamos del canal y arancamos de nuevo el script.

echo -e " \e[00;36mBorrando temporales\e[00m\n" && rm /tmp/$CANAL."$ID" > /dev/null 2>&1
kill -1 $LASTPID > /dev/null 2>&1
echo -e " \e[00;35m---\e[00m\n"
bash $0 # Comentar esta linea si no queremos que se ejecute de nuevo una vez terminada la emisión.
