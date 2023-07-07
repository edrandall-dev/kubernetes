show()
{ 
    echo
    echo -ne "==> "
    echo -ne "\033[7m$@\033[0m"
    echo -e " <=="
}

show "*** RUNNING: worker.sh ***"

show "Running /vagrant/join.sh"
cat /vagrant/scripts/join.sh
sh /vagrant/scripts/join.sh

show "*** COMPLETE: worker.sh ***"
