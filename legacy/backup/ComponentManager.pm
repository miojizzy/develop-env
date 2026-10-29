package ComponentManager;

use strict;
use warnings;

# 导出函数
use Exporter 'import';
our @EXPORT = qw(register install uninstall);

# 存储组件信息的哈希表
my %components;

# 注册组件的函数
sub register {
    my ($name, $install_cmd, $check_cmd, $post_install_cmd, $uninstall_cmd) = @_;
    
    $components{$name} = {
        install_cmd => $install_cmd,
        check_cmd => $check_cmd,
        post_install_cmd => $post_install_cmd,
        uninstall_cmd => $uninstall_cmd
    };
}

# 执行安装的函数
sub install {
    foreach my $name (keys %components) {
        print "检查组件: $name\n";
        
        my $check_result = system($components{$name}->{check_cmd});
        
        if ($check_result == 0) {
            print "$name 已经安装\n";
            next;
        }
        
        print "开始安装 $name...\n";
        my $install_result = system($components{$name}->{install_cmd});
        
        if ($install_result != 0) {
            die "安装 $name 失败\n";
        }
        
        print "$name 安装成功\n";
        
        if ($components{$name}->{post_install_cmd}) {
            print "执行安装后命令...\n";
            system($components{$name}->{post_install_cmd});
        }
    }
}

# 执行卸载的函数
sub uninstall {
    foreach my $name (reverse keys %components) {
        print "检查组件: $name\n";
        
        my $check_result = system($components{$name}->{check_cmd});
        
        if ($check_result != 0) {
            print "$name 未安装\n";
            next;
        }
        
        if (!$components{$name}->{uninstall_cmd}) {
            print "警告: $name 没有定义卸载命令，跳过\n";
            next;
        }
        
        print "开始卸载 $name...\n";
        my $uninstall_result = system($components{$name}->{uninstall_cmd});
        
        if ($uninstall_result != 0) {
            die "卸载 $name 失败\n";
        }
        
        print "$name 卸载成功\n";
    }
}

1; 