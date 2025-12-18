const { useState, useEffect, useCallback } = React;

function App() {
    const [isVisible, setIsVisible] = useState(false);
    const [currentJobs, setCurrentJobs] = useState([]);
    const [currentJob, setCurrentJob] = useState(null);
    const [isAdmin, setIsAdmin] = useState(false);
    const [isMenuOpen, setIsMenuOpen] = useState(false);
    const [activeTab, setActiveTab] = useState('jobs');
    const [pendingDelete, setPendingDelete] = useState(null);

    const formatMoney = (amount) => {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0
        }).format(amount);
    };

    const getJobIcon = (jobName) => {
        const icons = {
            'offduty': 'fa-mug-hot',
            'police': 'fa-shield-halved',
            'mechanic': 'fa-wrench',
            'trucker': 'fa-truck',
            'ambulance': 'fa-truck-medical',
            'taxi': 'fa-taxi',
            'lawyer': 'fa-gavel',
            'reporter': 'fa-microphone',
            'realestate': 'fa-house',
            'unemployed': 'fa-user-slash'
        };
        return icons[jobName.toLowerCase()] || 'fa-briefcase';
    };
    // fied version
    function GetParentResourceName() {
        if (typeof window.invokeNative === 'function') {
            return window.location.hostname === 'localhost' ? 's6la_multijob' : window.location.hostname;
        }
        return 's6la_multijob';
    }
    const closeUI = useCallback(() => {
        setIsVisible(false);
        setIsMenuOpen(false);
        setActiveTab('jobs');
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(() => {});
    }, []);

    const selectJob = (jobName) => {
        if (jobName === 'OFFDUTY') {
            fetch(`https://${GetParentResourceName()}/selectJob`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ job: null })
            });
        } else {
            fetch(`https://${GetParentResourceName()}/selectJob`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ job: jobName })
            });
        }
    };

    const showConfirm = (jobName, jobLabel) => {
        setPendingDelete({ jobName, jobLabel });
    };

    const closeConfirm = () => {
        setPendingDelete(null);
    };

    const confirmDelete = () => {
        if (pendingDelete) {
            fetch(`https://${GetParentResourceName()}/removeJob`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ job: pendingDelete.jobName })
            });
            closeConfirm();
        }
    };

    const toggleMenu = () => {
        setIsMenuOpen(prev => !prev);
    };

    const toggleTheme = () => {
        const body = document.body;
        const currentTheme = body.getAttribute('data-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        body.setAttribute('data-theme', newTheme);
        localStorage.setItem('multijob-theme', newTheme);
    };

    const switchToJobs = () => {
        setActiveTab('jobs');
        setIsMenuOpen(false);
    };

    const switchToSettings = () => {
        setActiveTab('settings');
    };

    useEffect(() => {
        const handleKeyDown = (event) => {
            if (event.key === 'Escape' || event.key === 'Backspace') {
                if (pendingDelete) {
                    closeConfirm();
                } else if (isMenuOpen) {
                    setIsMenuOpen(false);
                } else {
                    closeUI();
                }
            }
        };

        if (isVisible) {
            document.addEventListener('keydown', handleKeyDown);
            return () => document.removeEventListener('keydown', handleKeyDown);
        }
    }, [isVisible, isMenuOpen, pendingDelete, closeUI]);

    useEffect(() => {
        const handleMessage = (event) => {
            const data = event.data;

            if (data.action === 'updateJobs') {
                setCurrentJobs(data.jobs || []);
                setCurrentJob(data.currentJob || null);
                setIsAdmin(data.isAdmin || false);
            }

            if (data.action === 'close') {
                setIsVisible(false);
                setIsMenuOpen(false);
                setActiveTab('jobs');
            }

            if (data.action === 'open') {
                setIsVisible(true);
            }
        };

        window.addEventListener('message', handleMessage);
        return () => window.removeEventListener('message', handleMessage);
    }, []);

    useEffect(() => {
        const savedTheme = localStorage.getItem('multijob-theme') || 'dark';
        document.body.setAttribute('data-theme', savedTheme);
    }, []);

    if (!isVisible) return null;

    const offdutyJob = {
        job_name: 'OFFDUTY',
        job_label: 'OFFDUTY',
        grade: 0,
        grade_label: '',
        salary: 0
    };

    const isOffduty = !currentJob || currentJob.name === 'unemployed';
    const allJobs = [offdutyJob, ...currentJobs];

    return (
        <div className="job-container">
            <div className="job-wrapper">
                <div className="job-header">
                    <div className={`header-tabs ${isMenuOpen ? 'justify-start' : ''}`}>
                        <button 
                            className={`header-tab ${activeTab === 'jobs' ? 'active' : ''}`}
                            onClick={switchToJobs}
                        >
                            <i className="fas fa-briefcase"></i>
                            MY JOBS
                        </button>
                        {isMenuOpen && (
                            <button 
                                className={`header-tab ${activeTab === 'settings' ? 'active' : ''}`}
                                onClick={switchToSettings}
                            >
                                <i className="fas fa-cog"></i>
                                SETTINGS
                            </button>
                        )}
                    </div>
                    <button 
                        className={`menu-toggle ${isMenuOpen ? 'active' : ''}`}
                        onClick={toggleMenu}
                    >
                        <i className="fas fa-bars"></i>
                    </button>
                </div>

                {activeTab === 'jobs' && (
                    <div className="tab-content">
                        <div className="job-list">
                            {allJobs.map((job, index) => {
                                const jobName = job.job_name || job.name || 'OFFDUTY';
                                const isSelected = jobName === 'OFFDUTY' ? isOffduty : (currentJob && currentJob.name === jobName);
                                const isOffdutyItem = jobName === 'OFFDUTY';
                                const icon = getJobIcon(jobName);
                                const gradeLabel = job.grade_label || '';
                                const salary = job.salary || 0;

                                return (
                                    <div 
                                        key={jobName}
                                        className={`job-item ${isOffdutyItem ? 'offduty' : ''} ${isSelected ? 'selected' : ''}`}
                                        style={{ animationDelay: `${index * 0.05}s` }}
                                    >
                                        <div className="job-content">
                                            <div className="job-info">
                                                <div className="job-icon">
                                                    <i className={`fas ${icon}`}></i>
                                                </div>
                                                <div className="job-details">
                                                    <h3>{job.job_label || job.label || jobName}</h3>
                                                    {gradeLabel && <p>{gradeLabel}</p>}
                                                </div>
                                            </div>
                                            <div className="job-actions">
                                                {!isOffdutyItem && isAdmin && (
                                                    <button 
                                                        className="btn-delete"
                                                        onClick={() => showConfirm(jobName, job.job_label || jobName)}
                                                    >
                                                        <i className="fas fa-trash"></i>
                                                    </button>
                                                )}
                                                <button 
                                                    className={`btn-select ${isSelected ? 'selected' : ''}`}
                                                    onClick={() => selectJob(jobName)}
                                                >
                                                    {isSelected ? <><i className="fas fa-check"></i></> : 'SELECT'}
                                                </button>
                                            </div>
                                        </div>
                                        {!isOffdutyItem && (
                                            <div className="job-stats">
                                                <span><i className="fas fa-dollar-sign"></i> {formatMoney(salary)}</span>
                                            </div>
                                        )}
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                )}

                {activeTab === 'settings' && (
                    <div className="tab-content">
                        <div className="settings-list">
                            <div className="setting-item">
                                <span className="setting-label">Dark Mode</span>
                                <div 
                                    className={`toggle-switch ${document.body.getAttribute('data-theme') === 'dark' ? 'active' : ''}`}
                                    onClick={toggleTheme}
                                    style={{ cursor: 'pointer' }}
                                ></div>
                            </div>
                        </div>
                    </div>
                )}
            </div>

            {pendingDelete && (
                <div className="confirm-overlay active" onClick={closeConfirm}>
                    <div className="confirm-dialog" onClick={(e) => e.stopPropagation()}>
                        <h3>Remove Job</h3>
                        <p>Are you sure you want to remove "{pendingDelete.jobLabel}" from your jobs?</p>
                        <div className="confirm-actions">
                            <button className="confirm-btn cancel" onClick={closeConfirm}>Cancel</button>
                            <button className="confirm-btn confirm" onClick={confirmDelete}>Remove</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

ReactDOM.render(<App />, document.getElementById('root'));