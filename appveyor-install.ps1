$fork_user="ocaml"
$fork_branch="master"
$cyg_root="C:\cygwin64"
$cyg_setup="setup-x86_64.exe"
$cyg_mirror="http://cygwin.mirror.constant.com"
$appveyor_build_folder=".\"
$cyg_pkgs="mingw64-x86_64-gcc-core,mingw64-x86_64-headers,mingw64-x86_64-runtime,mingw64-x86_64-winpthreads"

if ( Test-Path env:fork_user ){
    $fork_user=$env:fork_user
}
if ( Test-Path env:fork_branch ){
    $fork_branch=$env:fork_branch
}
$appveyor_opam_sh="https://raw.githubusercontent.com/$fork_user/ocaml-ci-scripts/$fork_branch/appveyor-opam.sh"

if ( Test-Path env:cyg_pkgs ){
    $cyg_pkgs=%{$env:cyg_pkgs -replace " ",","}
}
if ( Test-Path env:cyg_mirror ){
    $cyg_mirror=$env:cyg_mirror
}
if ( Test-Path env:cyg_root ){
    $cyg_root=$env:cyg_root
    if ( $cyg_root -eq "C:\cygwin" ){
        $cyg_setup="setup-x86.exe"
    }
}
if ( Test-Path env:appveyor_build_folder ){
    $appveyor_build_folder=$env:appveyor_build_folder
}

# add further regular cygwin programs
function add_pkg($pkg){
    if ($cyg_pkgs) {
        $script:cyg_pkgs="$cyg_pkgs,$pkg"
    } else {
        $script:cyg_pkgs="$pkg"
    }
}

function add_program($exe,$pkg_name){
    if (!(Test-Path "$script:cyg_root\bin\$exe.exe")){
        if ($pkg_name){
            add_pkg $pkg_name
        } else {
            add_pkg $exe
	}
    }
}

add_program "curl"
add_program "diff" "diffutils"
add_program "git"
add_program "jq"
add_program "m4"
add_program "make"
add_program "patch"
add_program "perl"
add_program "rsync"
add_program "unzip"
#add_program "x86_64-w64-mingw32-gcc" "mingw64-x86_64-gcc-core"

$appveyor_local="$appveyor_build_folder\appveyor-opam.sh"
$webclient = New-Object System.Net.WebClient
$webclient.DownloadFile($appveyor_opam_sh,$appveyor_local)

$cont = [System.IO.File]::ReadAllText($appveyor_local).Replace("APPVEYOR_YML_VERSION=0","APPVEYOR_YML_VERSION=1")
[System.IO.File]::WriteAllText($appveyor_local, $cont)

if ($cyg_pkgs) {
    # always update cygwin, too. Otherwise the the new package might be incompatible
    # with the pre-installed cygwin1.dll
    $cyg_pkgs="cygwin,$cyg_pkgs"
    if (!(Test-Path "$cyg_root\$cyg_setup")){
        if (!(Test-Path "$cyg_root")){
            md "$cyg_root"
        }
        $webclient.DownloadFile("https://cygwin.com/$cyg_setup","$cyg_root\$cyg_setup")
    }
    & "$cyg_root\$cyg_setup" -qWnNdO -R $cyg_root -s $cyg_mirror -l $cyg_root\var\cache\setup -P $cyg_pkgs | Out-Host
}
