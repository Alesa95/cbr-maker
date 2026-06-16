Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


# FORMULARIO

$form = New-Object System.Windows.Forms.Form
$form.Text = "Renombrador Manga"
$form.Size = New-Object System.Drawing.Size(900,650)
$form.StartPosition = "CenterScreen"

# Variable global

$script = $null


# LABEL CARPETA

$lblCarpeta = New-Object System.Windows.Forms.Label
$lblCarpeta.Location = New-Object System.Drawing.Point(10,15)
$lblCarpeta.Size = New-Object System.Drawing.Size(700,20)
$lblCarpeta.Text = "No se ha seleccionado ninguna carpeta"
$form.Controls.Add($lblCarpeta)


# BOTÓN SELECCIONAR

$btnSeleccionar = New-Object System.Windows.Forms.Button
$btnSeleccionar.Location = New-Object System.Drawing.Point(730,10)
$btnSeleccionar.Size = New-Object System.Drawing.Size(140,30)
$btnSeleccionar.Text = "Seleccionar carpeta"
$form.Controls.Add($btnSeleccionar)


# TREEVIEW

$tree = New-Object System.Windows.Forms.TreeView
$tree.Location = New-Object System.Drawing.Point(10,50)
$tree.Size = New-Object System.Drawing.Size(860,500)
$form.Controls.Add($tree)


# BOTÓN RENOMBRAR

$btnRenombrar = New-Object System.Windows.Forms.Button
$btnRenombrar.Location = New-Object System.Drawing.Point(10,565)
$btnRenombrar.Size = New-Object System.Drawing.Size(200,40)
$btnRenombrar.Text = "Renombrar y generar CBR"
$form.Controls.Add($btnRenombrar)


# FUNCIÓN CARGAR ÁRBOL

function Add-FolderToTree {

    param(
        [string]$Path,
        [System.Windows.Forms.TreeNode]$ParentNode
    )

    Get-ChildItem -Path $Path | ForEach-Object {

        if ($_.PSIsContainer) {

            $numImagenes = (
                Get-ChildItem $_.FullName -File |
                Where-Object {
                    $_.Extension -match '\.(jpg|jpeg|png|webp|gif|bmp)$'
                }
            ).Count

            $textoNodo = "$($_.Name) ($numImagenes imágenes)"

            $node = New-Object System.Windows.Forms.TreeNode($textoNodo)

            if ($ParentNode -eq $null) {
                $tree.Nodes.Add($node) | Out-Null
            }
            else {
                $ParentNode.Nodes.Add($node) | Out-Null
            }

            Add-FolderToTree -Path $_.FullName -ParentNode $node
        }
        else {

            $node = New-Object System.Windows.Forms.TreeNode($_.Name)

            if ($ParentNode -eq $null) {
                $tree.Nodes.Add($node) | Out-Null
            }
            else {
                $ParentNode.Nodes.Add($node) | Out-Null
            }
        }
    }
}


# SELECCIÓN DE CARPETA

$btnSeleccionar.Add_Click({

$dialog = New-Object System.Windows.Forms.FolderBrowserDialog

if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {

    $script:carpeta = $dialog.SelectedPath

    $lblCarpeta.Text = $script:carpeta

    $tree.Nodes.Clear()

    $totalImagenes = (
        Get-ChildItem $script:carpeta -Recurse -File |
        Where-Object {
            $_.Extension -match '\.(jpg|jpeg|png|webp|gif|bmp)$'
        }
    ).Count

    $root = New-Object System.Windows.Forms.TreeNode(
        "$(Split-Path $script:carpeta -Leaf) ($totalImagenes imágenes)"
    )

    $tree.Nodes.Add($root) | Out-Null

    Add-FolderToTree -Path $script:carpeta -ParentNode $root

    $root.Expand()
}

})

# =========================
# BOTÓN AYUDA
# =========================
$btnAyuda = New-Object System.Windows.Forms.Button
$btnAyuda.Location = New-Object System.Drawing.Point(230,565)
$btnAyuda.Size = New-Object System.Drawing.Size(120,40)
$btnAyuda.Text = "Ayuda"
$form.Controls.Add($btnAyuda)

$btnAyuda.Add_Click({

    # Ventana de ayuda
    $helpForm = New-Object System.Windows.Forms.Form
    $helpForm.Text = "Ayuda"
    $helpForm.Size = New-Object System.Drawing.Size(700,550)
    $helpForm.StartPosition = "CenterParent"
    $helpForm.FormBorderStyle = "FixedDialog"
    $helpForm.MaximizeBox = $false
    $helpForm.MinimizeBox = $false

    # Caja de texto
    $txtHelp = New-Object System.Windows.Forms.TextBox
    $txtHelp.Location = New-Object System.Drawing.Point(10,10)
    $txtHelp.Size = New-Object System.Drawing.Size(660,450)
    $txtHelp.Multiline = $true
    $txtHelp.ScrollBars = "Vertical"
    $txtHelp.ReadOnly = $true
    $txtHelp.Font = New-Object System.Drawing.Font("Consolas",10)


# ARCHIVO DE AYUDA

$archivoAyuda = Join-Path $PSScriptRoot "ayuda.txt"

try {

    if (Test-Path $archivoAyuda) {
        $txtHelp.Text = Get-Content $archivoAyuda -Raw -Encoding UTF8
    }
    else {
        $txtHelp.Text = @"
No se encontró el archivo de ayuda.

Ruta esperada:

$archivoAyuda
"@
    }

}
catch {

    $txtHelp.Text = @"
Error al abrir el archivo de ayuda.

$($_.Exception.Message)
"@
}

# FIN BUSQUEDA ARCHIVO AYUDA

    $helpForm.Controls.Add($txtHelp)

    # Botón cerrar
    $btnCerrar = New-Object System.Windows.Forms.Button
    $btnCerrar.Text = "Cerrar"
    $btnCerrar.Size = New-Object System.Drawing.Size(100,35)
    $btnCerrar.Location = New-Object System.Drawing.Point(570,470)

    $btnCerrar.Add_Click({
        $helpForm.Close()
    })

    $helpForm.Controls.Add($btnCerrar)

    $helpForm.ShowDialog()

})


# EJECUTAR PROCESO


$btnRenombrar.Add_Click({

if (-not $script:carpeta) {

    [System.Windows.Forms.MessageBox]::Show(
        "Selecciona una carpeta primero."
    )

    return
}

try {

    $carpeta = $script:carpeta

    $subcarpetas = Get-ChildItem $carpeta |
        Sort-Object {
            [regex]::Replace(
                $_.Name,
                '\d+',
                { $args[0].Value.PadLeft(20) }
            )
        }

    foreach ($subcarpeta in $subcarpetas){

        $archivos = Get-ChildItem $subcarpeta.FullName |
            Sort-Object {
                [regex]::Replace(
                    $_.Name,
                    '\d+',
                    { $args[0].Value.PadLeft(20) }
                )
            }

        $contador = 0

        foreach($archivo in $archivos){

            if($contador -lt 10){
                $nuevoNombre = "$($subcarpeta.Name) - 0$contador.png"
            }
            else{
                $nuevoNombre = "$($subcarpeta.Name) - $contador.png"
            }

            Rename-Item `
                -Path $archivo.FullName `
                -NewName $nuevoNombre

            $contador++
        }
    }

    $zipDestino = "$carpeta.zip"

    if (Test-Path $zipDestino) {
        Remove-Item $zipDestino -Force
    }

    Compress-Archive `
        -Path $carpeta `
        -DestinationPath $zipDestino `
        -Force

    $cbrDestino = "$carpeta.cbr"

    if (Test-Path $cbrDestino) {
        Remove-Item $cbrDestino -Force
    }

    Rename-Item `
        -Path $zipDestino `
        -NewName (Split-Path $cbrDestino -Leaf) `
        -Force

    [System.Windows.Forms.MessageBox]::Show(
        "Proceso completado correctamente."
    )
}
catch {

    [System.Windows.Forms.MessageBox]::Show(
        $_.Exception.Message,
        "Error"
    )
}

})

$form.ShowDialog()